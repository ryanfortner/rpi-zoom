#!/bin/bash

BINARY_LINK='https://zoom.us/client/latest/zoom_x86_64.tar.xz'
ARCH="$(arch)"

# define error function
function error {
  echo -e "\\e[91m$1\\e[39m"
  exit 1
}

function install-depends() {
    if [ ! -z "$(file "$(readlink -f "/sbin/init")" | grep 64)" ];then
        if ! command -v box64 > /dev/null; then
            echo "Installing box64..."
            sudo wget https://box64.armlinux.ml/box64.list -O /etc/apt/sources.list.d/box64.list || error "Failed to install .list file."
            wget -qO- https://box64.armlinux.ml/KEY.gpg | sudo apt-key add - || error "Failed to install gpg key."
            sudo apt update && sudo apt install box64 -y || error "Failed to run apt update & apt install box64."
        else
            echo "box64 already installed, continuing..."
        fi
    elif [ ! -z "$(file "$(readlink -f "/sbin/init")" | grep 32)" ];then
        if ! command -v box86 > /dev/null; then
            echo "Installing box86..."
            sudo wget https://box86.armlinux.ml/box64.list -O /etc/apt/sources.list.d/box86.list || error "Failed to install .list file."
            wget -qO- https://box86.armlinux.ml/KEY.gpg | sudo apt-key add - || error "Failed to install gpg key."
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
    wget https://github.com/chunky-milk/ZoomClient-ARM/raw/master/zoom_x64_libs.zip || error "Failed to download zoom x64 libraries!"
    unzip zoom_x64_libs.zip || error "Failed to extract zoom libraries."
    mv zoom_x64_libs/* zoom/ || error "Failed to move zoom x64 libraries to zoom folder."
    rm -r $HOME/zoom_x64_libs || error "Failed to remove library folder."
    cd $HOME/zoom && wget https://github.com/chunky-milk/ZoomClient-ARM/raw/master/icon.png || error "Failed to download icon."
    echo "[Desktop Entry]
    Name=Zoom
    Exec=$HOME/zoom/zoom
    Icon=$HOME/zoom/icon.png
    Path=$HOME/zoom/
    Type=Application
    Comment=Teleconferencing Platform
    Categories=Network;
    Terminal=true" > $HOME/.local/share/applications/zoom.desktop || error "Failed to create desktop shortcut."
    cp $HOME/.local/share/applications/zoom.desktop $HOME/desktop || error "Failed to copy desktop shortcut to desktop."
}

# Things start to happen here
echo "Installing zoom for $ARCH."
echo "To cancel installation, click Ctrl+C in the next 5 seconds."
sleep 5

echo "Continuing..."
install-depends
setup-zoom
echo "Done"