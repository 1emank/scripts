#!/bin/bash
if [ "$(whoami)" != "root" ]
then
	echo "This script must be run as root"
	exit 1
fi

help_message="This script updates the packages of your linux system.

To run this script just run it as administrator. There's no need to pass
any arguments.

By default, a log is stored in \"/var/log/1emank/update.log\", you can
change this by editing the \"default_route\" variable of the script.
"
# To change the log location, modify the next variable
default_route="/var/log/1emank/update.log"

log_dir="$(dirname "$default_route")"
log_file="$(basename "$default_route")"

for arg in "$@"
do
    case "$arg" in
        -h|--help)
            echo "$help_message"
            exit 0 ;;
    esac
done

mkdir -p "$log_dir"
exec > >(tee "$log_dir/$log_file") 2>&1

###### ------------------------- BEGIN ------------------------- ######
printf "\n### Auto-update started: %s ###\n" "$(date)"

if which apt-get > /dev/null
then
    printf "## apt update ##\n"
    apt-get update
fi

if which apt > /dev/null
then
    printf "\n## apt upgrade ##\n"
    temp_var="$(apt list --upgradable 2> /dev/null | grep / | cut -d "/" -f1 | tr "\n" " ")"
    if [ -n "$temp_var" ]; then
        apt-get install "$temp_var" -y
    else
        echo "Nada que actualizar en apt"
    fi
fi

if which apt-get > /dev/null
then
    printf "\n## apt autoremove ##\n"
    apt-get autoremove -y --purge
fi

if which snap > /dev/null
then
    printf "\n## snap refresh ##\n"
    snap refresh
    snap changes | tail -2
fi

if which flatpak > /dev/null
then
    printf "\n## flatpak update ##\n"
    flatpak update -y
fi

if which canonical-livepatch > /dev/null
then
    printf "\n## canonical-livepatch refresh ##\n"
    canonical-livepatch refresh
fi

printf "\n### Auto-update finished: %s ###\n" "$(date)"
echo "-----See log in $log_dir/$log_file-----"
printf "\n\n"

exit 0
