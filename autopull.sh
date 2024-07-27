#!/bin/bash
pulled_something=false
didnt_pull_message="You didn't pull from any repository"
norepos_message="ERROR: Something went wrong and no repositories were found."
help_message="

This scripts pulls the changes from your git repositories.

To use this script you need to have a folder with all (or the intended)
repositories. Optionally, put this script there directly too:
I.E.: repos_folder
        ├repo1  
        ├repo2 (it can be a symbolic link too)
        ├...
        └autopull.sh (optional)

And then:
- If you put the script next to your repository folders, just run it
- If not, run the script giving the appropiate route as an argument
    - I.E.: ./autopull.sh route/to/repos_folder

You can specify the remote with -r|--remote \"remote name or path\" and
the branch with -b|--branch \"branch name\". If not specified, remote
will be \"origin\", and branch will be \"main\". Defaults can be set
from inside the script.
"
remote="origin"
branch="main"

if ! options=$(getopt -o r:b: --long remote:,branch: -n "Options" -- "$@")
then
    echo "Invalid options provided"
    exit 1
fi

eval set -- "$options"
while true; do
    case "$1" in
    -h|--help)
        echo "$help_message"
        exit 0 ;;
    -r|--remote)
        remote="$2"
        shift 2 ;;
    -b|--branch)
        branch="$2"
        shift 2 ;;
    --)
        shift
        break ;;
    *) 
        echo "Unknown error"
        exit 1 ;;
    esac
done

if [ -n "$1" ]
then
    route="$(readlink -f "$1")"
else
    route="$(dirname "$(readlink -f "$0")")"
fi

printf "\nLooking for repositories inside: %s\n\n" "$route"

readarray -d '' content < <(find "$route" -not -path "$route/*/*" -a -not -path "$route" -print0)
repos=()

for item in "${content[@]}"
do
    if [ ! -d "$item" ]
    then
        continue
    fi
    
    if git -C "$item" status 2&> /dev/null
    then
        repos+=("$item")
        printf "Repository found: %s\n" "$item"
    fi
done

if [ ${#repos[@]} -eq 0 ]
then
    echo "$norepos_message$help_message"
    exit 1
fi

for repo in "${repos[@]}"
do
    echo
    echo "Pulling from $repo:"
    if git -C "$repo" pull "$remote" "$branch"
    then
        pulled_something=true
    fi
done

if ! $pulled_something
then
    echo "$didnt_pull_message"
    exit 2
fi

exit 0