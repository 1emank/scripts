#!/bin/bash
help_message="This script does ...

To use it ...

Flags:
	...

"
###### -------------- USER CONFIGURABLE VARIABLES -------------- ######

# Configurable default variables

###### ------------ USER CONFIGURABLE VARIABLES:END ------------ ######

# Other default_variables here

if ! options=$(getopt -o h --long help -n 'Options' -- "$@")
then
    echo "Invalid options provided. See help with the --help flag."
    exit 1
fi

eval set -- "$options"
while true; do
	case "$1" in
	-h|--help) echo "$help_message"; exit 0 ;;
	--) shift ; break ;;
	*) echo "Unexpected error" ; exit 1 ;;
	esac
done

# Check permissions and that kind of stuff

# Maybe other default variables if they are dependent on permissions

# Start logging (if applicable)

###### ----------------------- FUNCTIONS ----------------------- ######

# Functions

###### ------------------------- BEGIN ------------------------- ######

# Do stuff

exit 0