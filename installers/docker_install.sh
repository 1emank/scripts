#!/bin/bash

printf "\nInstalling packages:\n\n"
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

read -p "Add user to docker group? [y/n]: " -n 1 -r choice
case "$choice" in
  [yYsSjJ])
    sudo groupadd docker
    sudo usermod -aG docker $USER
    ;;
  [nN])
    ;;
esac
echo "Done!"
