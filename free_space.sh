#!/bin/bash
help_message="This script liberates space in your local disk. 

It does this by deleting log files, cache files, and other unnecesary
files. To run this script just run it as administrator. There's no need
to pass any arguments.

By default, a log is stored in \"/var/log/1emank/free_space.log\". You can
change this with flags and arguments:
./free_space.sh [ --no-log | --log [[--yes] custom_route]]
./free_space.sh [-n | -l [[-y] custom_route]]

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
log_route="/var/log/1emank/free_space.log"
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

#format_number() { # in: raw number in K => out: formatted number
#	local times_divided=1
#	local number="$1"
#	local units=("K" "M" "G" "T" "P" "E")
#
#	while (( number > 1024 ))
#	do
#		times_divided=$(( times_divided + 1 ))
#		number=$(echo "$number / 1024" | bc)
#	done
#
#	echo "$number ${units[$times_divided]}B"
#}

###### ------------------------- BEGIN ------------------------- ######
before=$(df -h)

printf "\n### Space liberation started %s ###\n" "$(date)"
echo "WARN: If you dismount a storage device during the operation, the
results shown (or even the file systems) could be damaged."

if which journalctl > /dev/null
then
	printf "\n# journalctl --vacuum #\n"
	journalctl --vacuum-time=2weeks
	echo "# Section Completed #"
fi

if which snap > /dev/null
then
	printf "\n# snap clear #\n"
	set -eu
	snap list --all | awk '/disabled/{print $1, $3}' |
		while read -r snapname revision
		do
			snap remove "$snapname" --revision="$revision"
		done
	set +e
	echo "# Section Completed #"
fi

if which apt-get > /dev/null
then
	printf "\n# apt clean #\n"
	apt-get autoremove -y --purge
	apt-get clean
	echo "# Section Completed #"
fi

if which yum > /dev/null
then
	printf "\n# yum clean #\n"
	yum clean all
	echo "# Section Completed #"
fi

if which dnf > /dev/null
then
	printf "\n# dnf clean #\n"
	dnf clean all
	echo "# Section Completed #"
fi

if which flatpak > /dev/null
then
	printf "\n# flatpak cache #\n"
    flatpak uninstall --unused --delete-data -y
	rm -rfv /var/tmp/flatpak-cache-*
	echo "# Section Completed #"
fi

printf "\n# rm thumbinails #\n"
rm -rfv "/home/${SUDO_USER,,}/.cache/thumbnails/*"
echo "# Section Completed #"

printf "\n# Old log files #\n"
rm -rfv /var/log/*.gz
rm -rfv /var/log/*.old
rm -rfv /var/log/*.[0-9]
if [ -f "/home/${SUDO_USER,,}/.xsession-errors.old" ]; then
	rm -rfv "/home/${SUDO_USER,,}/.xsession-errors.old"
fi
if [ -d "/home/${SUDO_USER,,}/.local/share/sddm/" ]; then
	rm -rfv "/home/${SUDO_USER,,}/.local/share/sddm/*.gz"
	rm -rfv "/home/${SUDO_USER,,}/.local/share/sddm/*.old"
	rm -rfv "/home/${SUDO_USER,,}/.local/share/sddm/*.[0-9]"
fi
echo "# Section Completed #"

printf "\n# Emptying trash can #\n"
rm -rfv "/home/${SUDO_USER,,}/.local/share/Trash/files/*"
echo "# Section Completed #"

printf "\n### Space liberation finished %s ###\n" "$(date)"
printf "\nBefore liberation\n%s" "$before"
printf "\n\nAfter liberation\n%s" "$(df -h)"

if $logging
then
	printf "\n\nSee log in: %s\n\n" "$log_route"
fi

exit 0
