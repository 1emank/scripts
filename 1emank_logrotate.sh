#!/bin/bash

echo "You only need to run this script once."
target_file="/etc/logrotate.d/1emank"
if [ -f "$target_file" ]
then
    echo "The logrotate file already exists"
    exit 1
fi

### BEGIN
#/var/log/1emank/*.log {
#  rotate 5
#  monthly
#  minsize 10485760
#  compress
#  missingok
#  notifempty
#}
### END

sed -n '/### BEGIN/,/### END/ {
    /### BEGIN/!{/### END/!{s/^#//;p}}
}' "$0" > "$target_file"

if [ -f "$target_file" ]
then
    echo "Done!"
    exit 0
else
    echo "An error ocurred. You may need to run it with \"sudo\"."
    exit 1
fi