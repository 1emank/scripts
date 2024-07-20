#!/bin/bash

log_opt=true
nolog_opt=false

options=$(getopt -o nl --long no-log,log -n "Options" -- "$@")
if [ ! $? = 0 ]; then
    echo "Invalid options provided"
    exit 1
fi

eval set -- "$options"
while true; do
    case "$1" in
    -l|--log) log_opt=true; shift ;;
    -n|--no-log) nolog_opt=true; shift ;;
    --) shift ; break ;;
    *) echo "Unknown error" ; exit 1 ;;
    esac
done

if $log_opt && $nolog_opt; then
    echo "Invalid options provided. You can only choose -l|--log or -n|--no-log"
    echo "Logging (-l|--log), is the default behaviour."
    exit 1
fi

if [ ! `whoami` = root ]; then
	echo "This script must be run as root"
	exit 0
fi

if [ $log_opt = $nolog_opt ]; then
    echo "Incorrect options provided"
    exit 1
fi

if $log_opt ; then
    if [ "${SUDO_USER,,}" != "root" ] && [ ! -z "$SUDO_USER" ]; then
	    mkdir -p "/home/${SUDO_USER,,}/out"
	    exec > >(tee "/home/${SUDO_USER,,}/out/update") 2>&1
    else
	    mkdir -p "/var/log/custom_logs"
	    exec > >(tee "/var/log/custom_logs/update") 2>&1
    fi
fi

printf "### apt update ###\n"
apt-get update

printf "\n### apt upgrade ###\n"
temp_var=$(echo `apt list --upgradable 2> /dev/null | grep / | cut -d "/" -f1 | tr "\n" " "`)
if [ ! -z "$temp_var" ]; then
    apt-get install $temp_var -y
else
    echo "Nada que actualizar en apt"
fi

printf "\n### apt autoremove ###\n"
apt-get autoremove -y --purge

printf "\n### snap refresh ###\n"
snap refresh
snap changes | tail -2

printf  "\n### flatpak update ###\n"
flatpak update -y

printf "\n### canonical-livepatch refresh ###\n"
canonical-livepatch refresh

printf "\n### Auto-update finished: `date` ###\n"
if [ "${SUDO_USER,,}" != "root" ] && [ ! -z "$SUDO_USER" ]; then
    echo "-----See log in user/out/update-----"
    printf "\n\n"
else
    echo "---See log in /var/log/custom_logs/update---"
    printf "\n\n"
fi
