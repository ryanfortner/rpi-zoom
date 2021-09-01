#!/bin/bash

ARCH="$(arch)"

# define error function
function error {
  echo -e "\\e[91m$1\\e[39m"
  exit 1
}

echo "Uninstalling Zoom for $ARCH"
echo "To cancel uninstallation, click Ctrl+C in the next 5 seconds."
sleep 5

rm -r $HOME/zoom
rm -f $HOME/zoom.tar.xz
rm -f $HOME/zoom_x64_libs
rm -f $HOME/zoom_x64_libs.zip
rm $HOME/.local/share/applications/zoom.desktop && rm -f $HOME/.local/share/applications/zupdate.desktop && rm -f $HOME/.config/autostart/zupdate.desktop || error "Failed to remove desktop shortcuts"
rm $HOME/Desktop/zoom.desktop

echo "Have a nice day."
