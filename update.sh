#!/bin/bash
help_message="This script updates the packages of your linux system.

It uses the appropiate commands to update the packages of your package managers (apt, flatpak, etc). A log is stored in \"/var/log/1emank/update.log\". Run this script as administrator.

    Options:
./update.sh [ -h | --help ]
"
log_route="/var/log/1emank/update.log"

case "$1" in
    help|h|--help|-h)
        echo "$help_message"
        exit 0
        ;;
    #*) ;;
esac

if [ "$(whoami)" != "root" ]
then
    echo "This script must be run as root. See help with the --help flag"
    exit 1
fi

mkdir -p "$(dirname "$log_route")"
exec > >(tee -a "$log_route") 2>&1

###### ------------------------- BEGIN ------------------------- ######
printf "\n### Auto-update started: %s ###\n" "$(date)"

if which apt-get > /dev/null
then
    printf "\n## apt update, full-upgrade and cleanup ## (using apt-get)\n"
    apt-get update
    apt-get dist-upgrade -y
    apt-get autoremove -y --purge
    apt-get clean
fi

if which snap > /dev/null
then
    printf "\n## snap refresh ##\n"
    snap refresh
    snap changes | tail -2
fi

if which flatpak > /dev/null
then
    printf "\n## flatpak update and cleanup ##\n"
    flatpak update -y
    flatpak uninstall --unused --delete-data -y
    rm -rfv /var/tmp/flatpak-cache-*
fi

if which canonical-livepatch > /dev/null
then
    printf "\n## canonical-livepatch refresh ##\n"
    canonical-livepatch refresh
fi

printf "\n### Auto-update finished: %s ###\n\n" "$(date)"
printf "See log in: %s\n\n" "$log_route"

exit 0
