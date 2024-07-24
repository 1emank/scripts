#!/bin/bash
out=false
# Default behaviour gives you a log in /var/log/custom_logs
# To have a log in "~/out" use the -o|--out flag or, uncomment
# the next line
#out=true

options=$(getopt -o o --long out -n "Options" -- "$@")
if [ ! $? = 0 ]; then
    echo "Invalid options provided"
    exit 1
fi

eval set -- "$options"
while true; do
    case "$1" in
    -o|--out) out=true; shift ;;
    --) shift ; break ;;
    *) echo "Unknown error" ; exit 1 ;;
    esac
done

if [ ! `whoami` = root ]; then
	echo "This script must be run as root"
	exit 0
fi

if [ "${SUDO_USER,,}" != "root" ] && [ ! -z "$SUDO_USER" ] && $out ; then
    mkdir -p "/home/${SUDO_USER,,}/out"
    exec > >(tee "/home/${SUDO_USER,,}/out/update.log") 2>&1
else
    mkdir -p "/var/log/custom_logs"
    exec > >(tee "/var/log/custom_logs/update.log") 2>&1
fi

printf "\n### Auto-update started: `date` ###\n"

which apt-get > /dev/null
if [ $? -eq 0 ]; then
    printf "## apt update ##\n"
    apt-get update
fi

which apt > /dev/null
if [ $? -eq 0 ]; then
    printf "\n## apt upgrade ##\n"
    temp_var=$(echo `apt list --upgradable 2> /dev/null | grep / | cut -d "/" -f1 | tr "\n" " "`)
    if [ ! -z "$temp_var" ]; then
        apt-get install $temp_var -y
    else
        echo "Nada que actualizar en apt"
    fi
fi

which apt-get > /dev/null
if [ $? -eq 0 ]; then
    printf "\n## apt autoremove ##\n"
    apt-get autoremove -y --purge
fi

which snap > /dev/null
if [ $? -eq 0 ]; then
    printf "\n## snap refresh ##\n"
    snap refresh
    snap changes | tail -2
fi

which flatpak > /dev/null
if [ $? -eq 0 ]; then
    printf  "\n## flatpak update ##\n"
    flatpak update -y
fi

which canonical-livepatch > /dev/null
if [ $? -eq 0 ]; then
    printf "\n## canonical-livepatch refresh ##\n"
    canonical-livepatch refresh
fi

printf "\n### Auto-update finished: `date` ###\n"
if [ "${SUDO_USER,,}" != "root" ] && [ ! -z "$SUDO_USER" ] && $out ; then
    echo "-----See log in ~/out/update.log-----"
    printf "\n\n"
else
    echo "---See log in /var/log/custom_logs/update.log---"
    printf "\n\n"
fi

exit 0
