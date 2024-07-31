#!/bin/bash
is_directory_error="ERROR: The route you provided is a directory! Provide a valid route."
help_message="This script updates the packages of your linux system.

It uses the appropiate commands to update the packages of your package managers (apt, flatpak, etc). By default, a log is stored in \"/var/log/1emank/update.log\". Run this script as administrator.

    Options:
./update.sh [ -h | --help ]

    Flags:
-h, --help
    Shows this help

    Logging options:
./update.sh [ -n | -l[<custom route> [-y]] ]
            [ --no-log | --log[=<custom route> [--yes]] ]

-l, --log[=<custom_route>]
    Enables logging (default behaviour). Optionally, you can provide a custom route for the log file.
-n, --no-log
    Disables logging.
-y, --yes
    If a custom route is provided and the directory doesn't already exist, it usually asks for confirmation, with this flag it won't.

    You can also change the defaults by editing variables of the script (so you don't need to pass arguments):
logging - line 35
    Enables or disables logging.
sure_log - line 36
    If true, when you provide a custom log route through the --log argument, it won't ask you for confirmation (false by default).
log_route - line 37
    Defines the log location.
"
###### -------------- USER CONFIGURABLE VARIABLES -------------- ######

logging=true            # Default: true
sure_log=false          # Default: false
log_route="/var/log/1emank/update.log"
# Default: "/var/log/1emank/update.log"

###### ------------ USER CONFIGURABLE VARIABLES:END ------------ ######

custom_log=false
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

# If route is modified, you get here the absolute value. Otherwise it does nothing.
log_route=$(readlink -m "$log_route")

if $logging
then
    if $custom_log && ! $sure_log && [ ! -d "$log_route" ]
    then
        echo "The following action will create a log in $log_route"
        read -p "Do you want to continue? (y/n) " -n 1 -r choice
        case "$choice" in
            [yYsS]) ;;
            [nN]) echo "Action cancelled by user"; exit ;;
            *) echo "Invalid option"; exit 1 ;;
        esac
    elif $custom_log && ! $sure_log && [ -d "$log_route" ]
    then
        echo "$is_directory_error"
        exit 1
    fi
    mkdir -p "$(dirname "$log_route")"
    exec > >(tee -a "$log_route") 2>&1
fi

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
if $logging; then printf "See log in: %s\n\n" "$log_route"; fi

exit 0
