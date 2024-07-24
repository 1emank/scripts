#!/bin/bash
#cd "the absolute path to the folder with your repositories" # So you don't
# need to pass arguments or to be in a specific folder.

# To avoid unwanted behavior, make sure that the output of "ls" won't have
# any unwanted files or directories, either having the appropiate folder
# structure, or modifying the next line with the appropiate arguments
repos=($(ls))

for repo in "${repos[@]}"; do
    cd ${repos[i]}
    git pull origin main
    cd ..
done
