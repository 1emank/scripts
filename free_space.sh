#!/bin/bash
if [ ! `whoami` = root ]; then
	echo "This script must be run as root"
	exit 0
fi

if [ "${SUDO_USER,,}" != "root" ] && [ ! -z "$SUDO_USER" ]; then
	mkdir -p "/home/${SUDO_USER,,}/out"
	exec > >(tee "/home/${SUDO_USER,,}/out/free_space") 2>&1
else
	mkdir -p "/usr/share/custom_logs"
	exec > >(tee "/usr/share/custom_logs/free_space") 2>&1
fi

if [ -f "/usr/bin/journalctl" ]; then
	printf "\n### journalctl --vacuum:\n"
	journalctl --vacuum-time=2weeks
fi

if [ -f "/usr/bin/snap" ]; then
	printf "\n### snap clear\n"
	set -eu
	snap list --all | awk '/disabled/{print $1, $3}' |
		while read snapname revision; do
			snap remove "$snapname" --revision="$revision"
		done
fi
if [ -f "/usr/bin/apt" ]; then
	printf "\n### apt clean\n"
	apt clean 2> /dev/null
fi
if [ -f "/usr/bin/yum" ]; then
	printf "\n### yum clean\n"
	yum clean all
fi
if [ -f "/usr/bin/dnf" ]; then
	printf "\n### dnf clean\n"
	dnf clean all
fi
if [ -f "/usr/bin/flatpak" ]; then
	printf "\n### rm flatpak cache\n"
	rm -rfv /var/tmp/flatpak-cache-*
fi

printf "\n### rm thumbinails\n"
rm -rfv ~/.cache/thumbnails/*

printf "\n### Old log files\n"
rm -rfv /var/log/*.gz
rm -rfv /var/log/*.[0-9]
if [ -f "/home/${SUDO_USER,,}/.xsession-errors.old" ]; then
	cat /dev/null > /home/${SUDO_USER,,}/.xsession-errors.old
fi
#cat /dev/null > /home/${SUDO_USER,,}/.local/share/sddm/wayland-session.log
#cat /dev/null > /home/${SUDO_USER,,}/.local/share/sddm/xorg-session.log

if [ -f "/usr/bin/trash-empty" ]; then
	printf "\n### trash empty\n"
	trash-empty
fi

printf "\n### Space liberation finished `date`\n"

exit 0
