#!/bin/bash
is_directory_error="ERROR: The route you provided is a directory! Provide a valid route."
help_message="This script liberates space in your local disk. 

It does this by reducing or deleting log files, cache files, and other unnecesary files. By default, a log is stored in \"/var/log/1emank/free_space.log\". Run this script as administrator.

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

    Logging options:
./free_space.sh [other options] [-n | -l[custom_route [-y]] ]
                [other options] [--no-log | --log[=custom_route [--yes]] ]

-l, --log[=<custom_route>]
    Enables logging (default behaviour). Optionally, you can provide a custom route for the log file.
-n, --no-log
    Disables logging.
-y, --yes
    If a custom route is provided and the directory doesn't already exist, it usually asks for confirmation, with this flag it won't.

    You can also change the defaults by editing variables of the script (so you don't need to pass arguments):
snap_disabled_word - line 58
    Specifies --word (default by \$LANG)
def_dize - line 59
    Specifies --size in bytes (1048576 by default, equivalent to 1 MB).
full_depletion - line 60
    Equivalent to --full-depletion if true and to --reduction if false (false by default).
user_home - line 61
    Equivalent to --user-home if true (false, by default).

logging - line 63
    Enables or disables logging.
sure_log - line 64
    If true, when you provide a custom log route through the --log argument, it won't ask you for confirmation (false by default).
log_route - line 65
    Defines the log location.
"
if [[ "$LANG" == "es"* ]]; then snap_disabled_word="desactivado"
else snap_disabled_word="disabled" ;fi
###### -------------- USER CONFIGURABLE VARIABLES -------------- ######

#snap_disabled_word=""  # No default value
def_size=1048576        # Default: 1048576
full_depletion=false    # Default: false
user_home=false         # Default: false

logging=true            # Default: true
sure_log=false          # Default: false
log_route="/var/log/1emank/free_space.log"
#Default: "/var/log/1emank/free_space.log"

###### ------------ USER CONFIGURABLE VARIABLES:END ------------ ######

custom_log=false
options=$(getopt -o hl::nys: --long help,log::,no-log,yes,size: -n 'Options' -- "$@")

eval set -- "$options"
while true; do
    case "$1" in
    -h|--help)
        echo "$help_message"; exit 0 ;;
    -f|--full-depletion)
        full_depletion=true; shift;;
    -l|--log)
        logging=true
        log_route="${2:-$log_route}"
		if [ -n "${2:-}" ]; then custom_log=true; fi
		shift 2;;
    -n|--no-log)
        logging=false; shift;;
    -r|--reduction)
        full_depletion=false; shift;;
    -y|--yes)
        sure_log=true; shift;;
    -s|--size)
        def_size="$2"; shift 2;;
    -u|--user-home)
        user_home=true; shift;;
    -w|--word)
        snap_disabled_word="$2"; shift 2;;
    --) shift ; break ;;
    *) echo "Unexpected error" ; exit 1 ;;
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

###### ----------------------- FUNCTIONS ----------------------- ######

# This function is for a the final report, not implemented still
#format_number() { # in: raw number in K => out: formatted number
#    local times_divided=1
#    local number="$1"
#    local units=("K" "M" "G" "T" "P" "E")
#
#    while (( number > 1024 ))
#    do
#        times_divided=$(( times_divided + 1 ))
#        number=$(echo "$number / 1024" | bc)
#    done
#
#    echo "$number ${units[$times_divided]}B"
#}

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
            if (("$(stat --printf="%s" "$file")" < size))
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
if $logging; then printf "See log in: %s\n\n" "$log_route"; fi

exit 0
