#!/bin/bash
help_message="This script updates the packages of your linux system.

It uses the appropiate commands to update the packages of your package managers (apt, flatpak, etc). By default, a log is stored in \"/var/log/1emank/update.log\". Run this script as administrator.

    Options:
./update.sh [ -h | --help ]

    Flags:
-h, --help
    Shows this help

    Logging options:
./update.sh [ -n | -l[<custom route> [-y]] ]
./update.sh [ --no-log | --log[=<custom route> [--yes]] ]

-l, --log[=<custom_route>]
    Enables logging (default behaviour). Optionally, you can provide a custom route for the log file.
-n, --no-log
    Disables logging.
-y, --yes
    If a custom route is provided and the directory doesn't already exist, won't ask for confirmation.

You can also change the defaults by editing variables of the script (so you don't need to pass arguments):
- log_route - line 27 - defines the log location
- logging - line 28 - enables or disables logging
"
log_route="/var/log/1emank/update.log"
logging=true

custom_log=false
sure_log=false

options=$(getopt -o hl::ny --long help,log::,no-log,yes -n 'Options' -- "$@")

eval set -- "$options"
while true; do
    case "$1" in
    -h|--help)
		echo "$help_message"; exit 0 ;;
    -l|--log)
		logging=true
		log_route="${2:-$log_route}"
		if [ -n "${2:-}" ]; then custom_log=true; fi
		shift 2 ;;
    -n|--no-log)
		logging=false; shift;;
    -y|--yes)
		sure_log=true; shift ;;
    --) shift ; break ;;
    *) echo "Unexpected error" ; exit 1 ;;
    esac
done

if [ "$(whoami)" != "root" ]
then
    echo "This script must be run as root. See help with the --help flag"
    exit 1
fi

log_route=$(readlink -m "$log_route") # If route is modified, you get
log_dir="$(dirname "$log_route")"     # here the absolute value.
log_file="$(basename "$log_route")"   # Otherwise it does nothing

if $logging
then
    if $custom_log && ! $sure_log
    then
        echo "The following action will create a log in $log_route"
        read -p "Do you want to continue? (y/n) " -n 1 -r choice
        case "$choice" in
            [yYsS]) ;;
            [nN]) echo "Action cancelled by user"; exit ;;
            *) echo "Invalid option"; exit 1 ;;
        esac
    fi
    mkdir -p "$log_dir"
    exec > >(tee "$log_dir/$log_file") 2>&1
fi

###### ------------------------- BEGIN ------------------------- ######
printf "\n### Auto-update started: %s ###\n" "$(date)"

if which apt-get > /dev/null
then
    printf "## apt update, full-upgrade and cleanup ## (using apt-get)\n"
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

printf "\n### Auto-update finished: %s ###\n" "$(date)"
printf "See log in: %s/%s\n\n" "$log_dir" "$log_file"

exit 0