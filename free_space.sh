#!/bin/bash
help_message="This script liberates space in your local disk. 

It does this by reducing or deleting log files, cache files, and other unnecesary files. A log is stored in \"/var/log/1emank/free_space.log\". Run this script as administrator.

    Options:
./free_space.sh [-f|-r] [-s<bytes>] [-u] [-w<disable translated>]
                [--full-depletion|--reduction] [--size=<bytes>] [--user-home] [--word=<disable translated>]
                [-h | --help]

    Flags:
-h, --help
    Shows this help.
-f, --full-depletion
    Deletes or depletes log files (doesn't truncate).
-r, --reduction
    (As opposed to --full-depletion) Truncates log files to the default or specified --size (default behaviour).
-s, --size=BYTES
    In truncated (instead of deleted) files, defines the final size in bytes.
-u, --user-home
    BE CAREFUL. Deletes, recursively, ALL (instead of some) \".old\" files inside the user's \$HOME.
-w, --word=WORD
    To get the disabled packages from snap, this script finds a word in the output of \"snap list --all\". In English this word is \"disabled\". In case your snap client isn't in English or Spanish, you can specify the word with this argument.
"
if [[ "$LANG" == "es"* ]]; then
    snap_disabled_word="desactivado"
else
    snap_disabled_word="disabled"
fi

#snap_disabled_word=""  # No default value
def_size=1048576
full_depletion=false
user_home=false

log_route="/var/log/1emank/free_space.log"

options=$(getopt -o hfrs:uw: --long help,full-depletion,size:,user-home,word: -n 'Options' -- "$@")

eval set -- "$options"
while true; do
    case "$1" in
    -h|--help)
        echo "$help_message"; exit 0 ;;
    -f|--full-depletion)
        full_depletion=true; shift;;
    -r|--reduction)
        full_depletion=false; shift;;
    -s|--size)
        def_size="$2"; shift 2;;
    -u|--user-home)
        user_home=true; shift;;
    -w|--word)
        snap_disabled_word="$2"; shift 2;;
    --)
        shift ; break ;;
    *)
        echo "Unexpected error" ; exit 1 ;;
    esac
done

if [ "$(whoami)" != "root" ]
then
    echo "This script must be run as root. See help with the --help flag"
    exit 1
fi

if ! sudo_home=$(getent passwd "$SUDO_USER" | cut -d: -f6)
then sudo_home=""
fi

mkdir -p "$(dirname "$log_route")"
exec > >(tee -a "$log_route") 2>&1

###### ----------------------- FUNCTIONS ----------------------- ######

function reduce_file_type () { # location , extension, size
    local location="$1"
    if [ "${2-}" = "*" ]; then local file_name="*"
    elif [ -n "${2-}" ] ; then local file_name="*.$2"
    else local file_name="*.log"; fi
    local size="${3:-$def_size}"
    local to_clean=()

    readarray -d "" to_clean < <(find "$location" -name "$file_name" -print0)

    if ! $full_depletion
    then
        for file in "${to_clean[@]}"
        do
            if (("$(stat --printf="%s" "$file")" <= size)) || [ -d "$file" ]
            then continue
            fi

            tail -c "$size" "$file" > "$file.tmp"
            if mv -f "$file.tmp" "$file"
            then echo "'$file' reduced"
            fi
        done
    else
        for file in "${to_clean[@]}"
        do
            cat /dev/null > "$file"
            echo "'$file' depleted"
        done
    fi
}

###### ------------------------- BEGIN ------------------------- ######
before=$(df -h)

printf "\n### Space liberation started %s ###\n" "$(date)"

if which journalctl > /dev/null; then
    printf "\n# journalctl --vacuum #\n"
    journalctl --vacuum-time=2weeks
    echo "# Section Completed #"
fi

if which snap > /dev/null; then
    printf "\n# snap clear #\n"
    set -eu
    snap list --all | awk "/$snap_disabled_word/{print \$1, \$3}" |
        while read -r snapname revision
        do
            snap remove "$snapname" --revision="$revision"
        done
    set +e
    echo "# Section Completed #"
fi

if which apt-get > /dev/null; then
    printf "\n# apt clean #\n"
    apt-get autoremove -y --purge
    apt-get clean
    echo "# Section Completed #"
fi

if which yum > /dev/null; then
    printf "\n# yum clean #\n"
    yum clean all
    echo "# Section Completed #"
fi

if which dnf > /dev/null; then
    printf "\n# dnf clean #\n"
    dnf clean all
    echo "# Section Completed #"
fi

if which flatpak > /dev/null; then
    printf "\n# flatpak cache #\n"
    flatpak uninstall --unused --delete-data -y
    rm -rfv /var/tmp/flatpak-cache-*
    echo "# Section Completed #"
fi

if [ -d "${sudo_home:-?}" ]; then
    printf "\n# rm thumbinails #\n"
    rm -rfv "$sudo_home/.cache/thumbnails/*"
    echo "# Section Completed #"
fi

printf "\n# Log files #\n"
rm -rfv /var/log/*.gz
rm -rfv /var/log/*.old
rm -rfv /var/log/*.[0-9]
reduce_file_type "/var/log"
reduce_file_type "/var/log/syslog" "*"
if [ -d "${sudo_home:-?}/.local/share/sddm" ]
then reduce_file_type "$sudo_home/.local/share/sddm"; fi
echo "# Section Completed #"

if "$user_home" && [ -d "${sudo_home:-?}" ] ; then
    printf "\n# User log files #\n"
    readarray -d "" to_clean < <(find "$sudo_home" -name "*.old" -print0)
    rm -fv "${to_clean[@]}"
    reduce_file_type "$sudo_home"
    echo "# Section Completed #"
fi

printf "\n# Reducing tmp files #\n"
reduce_file_type "/tmp/" "*"
echo "# Section Completed #"

if [ -d "${sudo_home:-?}" ] || [ -d "/root/.local/share/Trash/files" ]
then
    printf "\n# Emptying trash can #\n"
    rm -rfv "$sudo_home/.local/share/Trash/files/**"
    rm -rfv "/root/.local/share/Trash/files/**"
    echo "# Section Completed #"
fi

printf "\n## Space liberation finished: %s ##\n" "$(date)"

printf "\nBefore liberation\n%s" "$before"
printf "\n\nAfter liberation\n%s" "$(df -h)"

printf "\n\n### END OF SCRIPT ###\n\n"
printf "See log in: %s\n\n" "$log_route"

exit 0
