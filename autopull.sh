#!/bin/bash
help_message="This script pulls the changes from your git repositories.

To use this script you need to have a folder with all (or the intended)
repositories. Optionally, put this script there directly too:
I.E.: repos
        ├repo1  
        ├repo2 (it can be a symbolic link too)
        ├...
        └autopull.sh (optional)

And then:
- If you put the script next to your repository folders, just run it
- If not, run the script giving the appropiate route as an argument
I.E.: ./autopull.sh route/to/repos

By default the remote is \"origin\" and the branch is \"main\". You can
change this through flags with arguments:
./autopull.sh [--remote=<remote>] [--branch=<branch>] [--ask] [<route>]
./autopull.sh [-r<remote>] [-b<branch>] [-a] [<route>]

    Flags:
-r<remote>, --remote=<remote>
    Specifies the remote (source) to pull from.
-b<branch>, --branch=<branch>
    Specifies the branch to pull from.
-a, --ask
    Asks for confirmation and allows to specify non-default remotes or
    branches for each repository.
-h, --help
    Shows this help

    Arguments:
route
    Folder to search for repositories in.

Defaults can be set by editing the script:
- remote - line 42
- branch - line 43
- route - line 46
"
def_remote="origin"
def_branch="main"
route="$(dirname "$(readlink -f "$0")")"
# Uncomment and edit the next line to specify your repos folder
#route=

ask=false
pulled_something=false
didnt_pull_message="You didn't pull from any repository"
norepos_message="ERROR: Something went wrong and no repositories were found."

if ! options=$(getopt -o r:b:ah --long remote:,branch:,ask,help -n "Options" -- "$@")
then
    echo "Invalid options provided. See help with the --help flag."
    exit 1
fi

eval set -- "$options"
while true; do
    case "$1" in
    -h|--help)
        echo "$help_message"
        exit 0 ;;
    -a|--ask)
        ask=true
        shift 1;;
    -r|--remote)
        def_remote="$2"
        shift 2 ;;
    -b|--branch)
        def_branch="$2"
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
fi

printf "\nLooking for repositories inside: %s\n\n" "$route"

readarray -d "" content < <(find "$route" -not -path "$route/*/*" -a -not -path "$route" -print0)
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
    printf "\nPulling from %s:\n" "$repo"
    if $ask
    then
        read -p "Pull from this remote \"$def_remote\" and branch \"$def_branch\"?" -n 1 -r choice
        echo
	    case "$choice" in
	    	[yYsS]) remote="$def_remote"; branch="$def_branch";;
	    	[nN])
                read -p "Specify remote:" -r remote
                if [ -z "$remote" ]; then
                    remote="$def_remote"
                fi
                read -p "Specify branch:" -r branch
                if [ -z "$branch" ]; then
                    branch="$def_branch"
                fi
                ;;
        esac
    else
        remote="$def_remote"
        branch="$def_branch"
    fi

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