#!/bin/bash
if [ ${#@} -eq 0 ]; then
	echo "This script depletes files periodically."
	echo "You must pass at least one file to be depleted."
	exit 1
fi

if [ "$(whoami)" != "root" ]; then
	printf "Some files might need root privileges to be depleted\n\n"
fi

printf "The following files will be depleted periodically:\n"
for item in ${@}; do
	printf "%s \n" "$item"
done
echo
read -p "Are you sure to proceed? (y/n) " -n 1 -r choice
case "$choice" in
	[yYsS]);;
	[nN]) printf "\nAction cancelled by user\n"; exit 1;;
	*) echo "Invalid option"; exit 1;;
esac

echo
while true ; do
	for item in ${@}; do
		printf "Depleting '$item' at %s. %s liberated.\n" "$(date)" "$(du -h "$item" | awk '{printf $1}')"
		printf "\0" > "$item"
	done
	sleep 600
done
