#!/bin/bash

base_path="$HOME/dev/sisu-tech/"
packages_path="packages/"

# Array of extensions to watch
watch_extensions=("mts" "json" "ts")

# Select the service
echo "Select service to work on:"
cd $base_path/backend/
select service_name in $(ls -d */); do
    break
done

cd $base_path/backend/$service_name
pnpm run start:telepresence &
PID_TELEPRESENCE=$!

# function commands to execute on each change
# $1: package absolute path
function on_change_package {
    local package_path=$1

    # Stopping telepresence if running
    if [ ! -z $PID_TELEPRESENCE ] && kill -0 $PID_TELEPRESENCE 2>/dev/null; then
        echo "Killing telepresence"
        kill -SIGINT $PID_TELEPRESENCE
    fi

    cd $package_path
    pnpm run build

    # Restarting telepresence
    cd $base_path/backend/$service_name
    pnpm run start:telepresence &
    PID_TELEPRESENCE=$!
}

regex_ext=$(printf "|%s" "${watch_extensions[@]}")
regex_ext=${regex_ext:1} # remove the leading '|'
regex="^(.*/packages/[^/]+)/src/.*\.($regex_ext)$"

# Monitor the target directory
echo "Watching $base_path/$packages_path"

fswatch -0 $base_path/$packages_path | while read -d "" event; do
    if [[ $event =~ $regex ]]; then
        on_change_package "${BASH_REMATCH[1]}"
    fi
done
