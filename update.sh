#!/bin/bash
help_message="This script updates the packages of your linux system.

    It uses the appropiate commands to update the packages of your package managers (apt, flatpak, etc). Run this script as administrator. 

    Options:
. update.sh [ -h | --help ]

    A log is stored in \"/var/log/1emank/update.log\". Set up log rotation manually or use the \"1emank_logrorate.sh\" script from this repository."

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
    echo "This script must be run as root. See help with --help."
    exit 1
fi

mkdir -p "$(dirname "$log_route")"
exec > >(tee -a "$log_route") 2>&1

###### ------------------------- BEGIN ------------------------- ######
printf "### START %s\n" "$(date)"

if which apt-get > /dev/null
then
    echo "# apt #"
    apt_out="$(\
      apt-get -U dist-upgrade -yqq | tee /dev/tty;
      apt-get autoremove -yqq --purge | tee /dev/tty;
      apt-get clean | tee /dev/tty \
    )"
    if [ -z "$apt_out" ]; then
        echo "Nothing changed."
    fi
fi

if which snap > /dev/null
then
    echo "# snap #"
    snap refresh
    snap changes | tail -2
fi

if which flatpak > /dev/null
then
    echo "# flatpak #"
    printf "Update result:"
    flatpak update --noninteractive -y
    flatpak uninstall --noninteractive --unused --delete-data -y
    rm -rfv /var/tmp/flatpak-cache-*
fi

if which canonical-livepatch > /dev/null
then
    printf "# canonical-livepatch #"
    canonical-livepatch refresh
fi

printf "### END %s\n" "$(date)"
printf "\nSee log in: %s\n\n" "$log_route" > /dev/tty

exit 0
