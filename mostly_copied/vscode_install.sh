#!/bin/bash

sudo apt install apt-transport-https
sudo apt update

read -p "Install [r]egular code or code-[i]nsiders? [r/i]: " -n 1 -r choice
case "$choice" in
  [rR]) sudo apt install code ;;
  [iI]) sudo apt install code-insiders ;;
esac
echo "Done!"
