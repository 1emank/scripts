#!/bin/bash
help_message="This script updates the packages of your linux system.

It uses the appropiate commands to update the packages of your package
managers (apt, flatpak, etc). To run this script just run it as
administrator. There's no need to pass any arguments.

By default, a log is stored in \"/var/log/1emank/update.log\". You can
change this with flags and arguments:
./update.sh [ --no-log | --log [[--yes] custom_route]]
./update.sh [-n | -l [[-y] custom_route]]

	Flags:
-l, --log
	Enables logging (default behaviour)
-n, --no-log
	Disables logging
-y, --yes
	If a custom route is provided, won't ask for confirmation
-h, --help
	Shows this help

	Arguments:
custom_route
	Route in which the log will be saved

You can also change the defaults by editing variables of the script (so
you don't need to pass arguments):
- \"log_route\" - line 33 - defines the log location
- \"logging\" - line 35 - enables or disables logging
"
# To change the log location, modify the next variable
log_route="/var/log/1emank/update.log"
# To disable logging, set the following variable to "false"
logging=true

custom_log=false
sure=false

options=$(getopt -o hlny --long help,log,no-log,yes -n 'Options' -- "$@")

eval set -- "$options"
while true; do
	case "$1" in
	-h|--help) echo "$help_message"; exit 0 ;;
	-l|--log) logging=true; shift ;;
	-n|--no-log) logging=false; shift;;
	-y|--yes) sure=true; shift ;;
	--) shift ; break ;;
	*) echo "Unexpected error" ; exit 1 ;;
	esac
done

if [ "$(whoami)" != "root" ]
then
	echo "This script must be run as root. See help with the --help flag"
	exit 1
fi

if [ -n "$1" ]
then
	log_route=$(readlink -m "$1")
	custom_log=true
fi

log_dir="$(dirname "$log_route")"
log_file="$(basename "$log_route")"

if $logging
then
	if $custom_log && ! $sure
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
    printf "## apt-get update ##\n"
    apt-get update
    printf "\n## apt-get full-upgrade ##\n"
    apt-get full-upgrade -y
    printf "\n## apt-get autoremove ##\n"
    apt-get autoremove -y --purge
    printf "\n## apt-get clean ##\n"
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
    printf "\n## flatpak update ##\n"
    flatpak update -y
    flatpak uninstall --unused --delete-data
    flatpak cache --delete
fi

if which canonical-livepatch > /dev/null
then
    printf "\n## canonical-livepatch refresh ##\n"
    canonical-livepatch refresh
fi

printf "\n### Auto-update finished: %s ###\n" "$(date)"
printf "See log in: %s/%s\n" "$log_dir" "$log_file"

exit 0
