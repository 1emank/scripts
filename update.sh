#!/bin/bash
help_message="This script updates the packages of your linux system.

    It uses the appropiate commands to update the packages of your package managers (apt, flatpak, etc). Run this script as administrator. 

    Options:
. update.sh [ -h | --help ]

    Exit status:
        0    OK
	1    If you don't run it as root
	2    If some error happened

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

track_ec() {
    if [ $? -ne 0 ] || [ $exit_code -ne 0 ]; then
	exit_code=2
    fi
}

mkdir -p "$(dirname "$log_route")"
exec > >(tee -a "$log_route") 2>&1

###### ------------------------- BEGIN ------------------------- ######
printf "### START %s\n" "$(date)"

exit_code=0
trap 'track_ec' BEBUG
if which apt-get > /dev/null; then
    echo "# apt #"
    apt-get update -qq
    upgradable=($(apt list --upgradable -qq 2>/dev/null | awk -F 'NR>1 {print $1}'))
    if [ "${#upgradable[@]}" -ne 0 ]; then
        apt-get install ${upgradable[@]} -yqq
        apt-get autoremove -yqq --purge
        apt-get clean
    else
        echo "Nothing changed."
    fi
fi

if which snap > /dev/null; then
    echo "# snap #"
    snap refresh
    snap changes | tail -2
fi

if which flatpak > /dev/null; then
    echo "# flatpak #"
    printf "Update result:"
    flatpak update --noninteractive -y
    flatpak uninstall --noninteractive --unused --delete-data -y
    rm -rfv /var/tmp/flatpak-cache-*
fi

if which canonical-livepatch > /dev/null; then
    printf "# canonical-livepatch #"
    canonical-livepatch refresh
fi

trap - DEBUG
printf "### END %s\n" "$(date)"
printf "\nSee log in: %s\n\n" "$log_route" > /dev/tty

exit $exit_code
