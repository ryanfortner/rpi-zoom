#!/bin/bash

BINARY_LINK_64='https://zoom.us/client/latest/zoom_x86_64.tar.xz'
ARCH="$(arch)"

# define error function
function error {
  echo -e "\\e[91m$1\\e[39m"
  exit 1
}

function check_internet() {
  printf "Checking if you are online..."
  wget -q --spider http://github.com
  if [ $? -eq 0 ]; then
    echo "Online. Continuing."
  else
    error "Offline. Go connect to the internet then run the script again."
  fi
}

function install-depends() {
    if [ ! -z "$(file "$(readlink -f "/sbin/init")" | grep 64)" ];then
        if ! command -v box64 > /dev/null; then
            echo "Installing box64..."
            sudo wget https://ryanfortner.github.io/box64-debs/box64.list -O /etc/apt/sources.list.d/box64.list || error "Failed to add box64.list to apt sources!"
            wget -O- https://ryanfortner.github.io/box64-debs/KEY.gpg | gpg --dearmor | sudo tee /usr/share/keyrings/box64-debs-archive-keyring.gpg || error "Failed to install gpg key!"
            sudo apt update && sudo apt install box64 -y || error "Failed to run apt update/apt install box64!"
        else
            echo "box64 already installed, continuing..."
        fi
    elif [ ! -z "$(file "$(readlink -f "/sbin/init")" | grep 32)" ];then
        if ! command -v box86 > /dev/null; then
            echo "Installing box86..."
            sudo wget https://ryanfortner.github.io/box86-debs/box86.list -O /etc/apt/sources.list.d/box86.list || error "Failed to install .list file."
            wget -qO- https://ryanfortner.github.io/box86-debs/KEY.gpg | gpg --dearmor | sudo tee /usr/share/keyrings/box86-debs-archive-keyring.gpg || error "Failed to install gpg key."
            sudo apt update && sudo apt install box86 -y || error "Failed to run apt update & apt install box86."
        else
            echo "box86 already installed, continuing..."
        fi
    else
        error "Failed to detect architecture. Exiting..."
    fi
}

function setup-zoom() {
    # remove old zoom files upon update
    rm -rf $HOME/zoom
    rm -f $HOME/zoom.tar.xz
    rm -rf $HOME/zoom_x64_libs
    rm -f $HOME/zoom_x64_libs.zip
    rm -f $HOME/.local/share/applications/zoom.desktop
    rm -f $HOME/Desktop/zoom.desktop
    cd $HOME || error "Failed to navigate to user home directory."
    if [ ! -z "$(file "$(readlink -f "/sbin/init")" | grep 64)" ];then
      echo "downloading zoom x86_64..."
      wget $BINARY_LINK_64 -O zoom.tar.xz || error "Failed to download zoom for arm64!"
      tar -xvf zoom.tar.xz || error "Failed to extract Zoom archive."
      wget https://github.com/ryanfortner/rpi-zoom/raw/master/zoom_x64_libs.zip || error "Failed to download zoom x64 libraries!"
      unzip zoom_x64_libs.zip || error "Failed to extract zoom libraries."
      mv zoom_x64_libs/* zoom/ || error "Failed to move zoom x64 libraries to zoom folder."
      rm -r $HOME/zoom_x64_libs || error "Failed to remove library folder."
    elif [ ! -z "$(file "$(readlink -f "/sbin/init")" | grep 32)" ];then
      echo "downloading zoom for 32-bit..."
      wget 'https://zoom.us/client/5.4.53391.1108/zoom_i686.tar.xz' -O zoom.tar.xz || wget 'https://zoom.com/client/5.4.53391.1108/zoom_i686.tar.xz' -O zoom.tar.xz || wget 'https://d11yldzmag5yn.cloudfront.net/prod/5.4.53391.1108/zoom_i686.tar.xz' -O zoom.tar.xz|| error 'Failed to download Zoom i686!'
      sudo apt-get install libxcb-xtest0 libxcb-xfixes0 libturbojpeg0 -y || error "Failed to install dependencies!"
      tar -xvf zoom.tar.xz || error "Failed to extract Zoom archive."
    else
        error "Failed to detect architecture. Exiting..."
    fi
    rm zoom.tar.xz || error "Failed to remove zoom archive, as it isn't needed anymore."
    cd $HOME/zoom && wget https://github.com/ryanfortner/rpi-zoom/raw/master/icon.png || error "Failed to download icon."
    if [ ! -f $HOME/.config/mimeapps.list ]; then
        touch $HOME/.config/mimeapps.list
    fi
    if [ -z "$(cat ~/.config/mimeapps.list | grep 'zoom.desktop')" ];then
        echo "Associating Zoom mimetypes..."
        echo "[Added Associations]
x-scheme-handler/zoomus=zoom.desktop;
x-scheme-handler/zoommtg=zoom.desktop;" >> ~/.config/mimeapps.list
    fi
    echo "[Desktop Entry]
Name=Zoom
Exec=$HOME/zoom/zoom
Icon=$HOME/zoom/icon.png
Path=$HOME/zoom/
Type=Application
Comment=Teleconferencing Platform
Categories=Network;
Terminal=false" > $HOME/.local/share/applications/zoom.desktop || error "Failed to create desktop shortcut."
    cp $HOME/.local/share/applications/zoom.desktop $HOME/Desktop || error "Failed to copy desktop shortcut to desktop."
}

function install-updater() {
  mkdir -p $HOME/zupdate
  cd $HOME/zupdate
  wget https://raw.githubusercontent.com/ryanfortner/rpi-zoom/master/autoupdate.sh || error "Failed to download autoupdate script."
  chmod +x autoupdate.sh
  mkdir -p $HOME/.config/autostart
  echo "[Desktop Entry]
Name=Zoom Updater
Exec=$HOME/zupdate/autoupdate.sh
Icon=$HOME/zoom/icon.png
Path=$HOME/zupdate
Type=Application
Comment=Teleconferencing Platform (Updater)
Categories=Network;
Terminal=false" > $HOME/.config/autostart/zupdate.desktop || error "Failed to create autoupdate entry."
  echo "[Desktop Entry]
Name=Zoom Updater
Exec=$HOME/zupdate/autoupdate.sh
Icon=$HOME/zoom/icon.png
Path=$HOME/zupdate
Type=Application
Comment=Teleconferencing Platform (Updater)
Categories=Network;
Terminal=true" > $HOME/.local/share/applications/zupdate.desktop || error "Failed to create desktop entry"
  echo "
Zoom will now be updated on each boot of the OS. To update manually, click on the Zoom Updater icon in the menu."
}

function endmessage() {
    RED='\033[0;31m'
    NC='\033[0m' 
    echo -e "${RED}!!! WARNING: Don't update Zoom from within the program!"
    echo -e "${RED}Instead, simply run this script again to update."
    echo -e "${NC}Have a nice day."
}

# Things start to happen here
echo "Installing zoom for $ARCH."
echo "To cancel installation, click Ctrl+C in the next 5 seconds."
sleep 5

echo "Continuing..."
check_internet
install-depends
setup-zoom
printf "Do you want automatic updates on each boot? "
while true; do
  read -p "(y/n) " choice
  case "$choice" in 
    y|Y ) install-updater && break ;;
    n|N ) echo "Updates will not be enabled." && endmessage && break ;;
    * ) echo "Invalid input!";;
  esac
done
echo "Done"
