#!/bin/bash

BINARY_LINK='https://zoom.us/client/latest/zoom_x86_64.tar.xz'
ARCH="$(arch)"

# define error function
function error {
  echo -e "\\e[91m$1\\e[39m"
  exit 1
}

function check_internet() {
  printf "checking if you are online..."
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
            sudo wget http://ryanfortner.github.io/box64-debs/box64.list -O /etc/apt/sources.list.d/box64.list || error "Failed to install .list file."
            wget -qO- http://ryanfortner.github.io/box64-debs/KEY.gpg | sudo apt-key add - || error "Failed to install gpg key."
            sudo apt update && sudo apt install box64 -y || error "Failed to run apt update & apt install box64."
        else
            echo "box64 already installed, continuing..."
        fi
    elif [ ! -z "$(file "$(readlink -f "/sbin/init")" | grep 32)" ];then
        if ! command -v box86 > /dev/null; then
            echo "Installing box86..."
            sudo wget http://ryanfortner.github.io/box86-debs/box86.list -O /etc/apt/sources.list.d/box86.list || error "Failed to install .list file."
            wget -qO- http://ryanfortner.github.io/box86-debs/KEY.gpg | sudo apt-key add - || error "Failed to install gpg key."
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
    wget $BINARY_LINK -O zoom.tar.xz || error "Failed to download Zoom archive."
    tar -xvf zoom.tar.xz || error "Failed to extract Zoom archive."
    rm zoom.tar.xz || error "Failed to remove zoom archive, as it isn't needed anymore."
    wget https://github.com/ryanfortner/ZoomClient-ARM/raw/master/zoom_x64_libs.zip || error "Failed to download zoom x64 libraries!"
    unzip zoom_x64_libs.zip || error "Failed to extract zoom libraries."
    mv zoom_x64_libs/* zoom/ || error "Failed to move zoom x64 libraries to zoom folder."
    rm -r $HOME/zoom_x64_libs || error "Failed to remove library folder."
    cd $HOME/zoom && wget https://github.com/ryanfortner/ZoomClient-ARM/raw/master/icon.png || error "Failed to download icon."
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

TIME="$(date)"
echo "
=============================
$TIME
=============================" >> $HOME/zoom-update.log
NOWDAY="$(printf '%(%Y-%m-%d)T\n' -1)"
NOWTIME="$(date +"%T")"
check_internet >> $HOME/zoom-update.log
echo "[$NOWTIME | $NOWDAY] Internet check complete." >> $HOME/zoom-update.log
install-depends && setup-zoom >> $HOME/zoom-update.log
echo "[$NOWTIME | $NOWDAY] Zoom update complete." >> $HOME/zoom-update.log
