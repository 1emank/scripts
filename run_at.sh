#!/bin/bash

### Unfinished ###
echo 'Unfinished script'
exit
##################


### Functions
function ask_permission() {
	z_counter=0
	while true ; do
    read -p "Do you want to continue? (y/n) " -n 1 -r choice
    echo
	case "$choice" in
		[yYsS]) break ;;
		[nN]) echo "Action cancelled by user"; exit ;;
    esac
    if [ $z_counter -gt 1 ] ; then echo "Too many tries: Cancelled"; exit ; fi
    z_counter=$(( $z_counter+1 ))
	done
}

### Check
# Parse command line options
options=`getopt -o skr --long startup,shutdown,reboot -n 'When to execute my script' -- "$@"`

# Check for errors (must be inmediatly after getopt)
# otherwise the $? variable changed, and the comparison doesn't work
if [ $? -ne 0 ]; then
	echo "Error: Failed to parse command line options"
	exit 1
fi

# Initialize variables
startup_f=false
shutdown_f=false
reboot_f=false

# Extract the options and their arguments into variables
eval set -- "$options"
while true; do
	case "$1" in
	-s | --startup) startup_f=true; shift ;;
	-k | --shutdown) shutdown_f=true; shift ;;
	-r | --reboot) reboot_f=true; shift ;;
	--) shift ; break ;; # Necessary to separate flags from arguments
	*) printf "Unexpected error" ; exit 1 ;;
	esac
done

# Check if at least one flag is provided
if ! $startup_f && ! $shutdown_f && ! $reboot_f ; then
	echo "Error: At least one of the flags (-s, -k, -r or --startup, --shutdown, --reboot) is required"
	exit 1
fi

# Check for missing argument
if [ -z "$1" ]; then printf "Error: Missing argument"; exit 1; fi
# Check file
if [ ! -f "$1" ]; then printf "File doesn't exist";	exit 1; fi

source_file=`realpath $1`
file_name=`basename $source_file`

### MAIN ###

echo "This is your script: $source_file"
if [ -f /etc/init.d/custom_script_$file_name ]; then
	echo "There's already a script with the same name in the destination"
	ask_permission
fi
read -n 1 -s -r -p "Press any key to continue and check your script"

#-p allows text to be displayed 
#-n defines the required character count to stop reading
#-s hides the user's input
#-r causes the string to be interpreted "raw" (without considering backslash escapes)

less $source_file
printf "\n### Script reading closed ###\n"
echo "The following action will make your script run at:"

if $startup_f ; then echo "- Startup" ; fi
if $shutdown_f ; then echo "- Shutdown"; fi
if $reboot_f ; then echo "- Reboot"; fi

ask_permission

# Actual work
if $startup_f || $shutdown_f || $reboot_f ; then
	cp -iv $source_file /etc/init.d/custom_script_$file_name
	
fi
