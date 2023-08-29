#!/bin/bash

function command_exists() {
    type "$1" &>/dev/null
}

function install_fswatch_linux() {
    sudo apt-get update
    sudo apt-get install -y fswatch
}

function install_fswatch_mac() {
    brew install fswatch
}

function check_fswatch() {
    if command_exists fswatch; then
        return
    fi

    case "$OSTYPE" in
        linux-gnu*)
            install_fswatch_linux
            ;;
        darwin*)
            install_fswatch_mac
            ;;
        *)
            echo "Unknown operating system. Please install fswatch manually."
            ;;
    esac
}

check_fswatch


base_path="$HOME/dev/sisu-tech/"
packages_path="packages/"

# Array of extensions to watch
watch_extensions=("mts" "json" "ts")

# clean up telepresence
telepresence quit

# Select the services
echo "Select services to work on:"
cd $base_path/backend/

select service_name in $(ls -d */); do
    if [ -n "$service_name" ]; then
        service_names+=("$service_name")
        echo ""
        echo "${service_names[@]}"
        echo ""
        echo "Do you want to select another service? (y/N)"
        read answer
        if [ "$answer" != "y" ]; then
            break
        fi
    else
        echo "Invalid selection"
    fi
done

for service_name in "${service_names[@]}"; do
    cd $base_path/backend/$service_name
    pnpm run start:telepresence &
done

# function commands to execute on each change
# $1: package absolute path
function on_change_package {
    local package_path=$1

    cd $package_path
    pnpm run build

    echo "Restarting telepresence"

    # Restarting telepresence
    for service_name in "${service_names[@]}"; do

        # restart telepresence making a change in the main.mts file
        local app_file_path="$base_path""backend/$service_name""src/app.mts"

        echo modifiying $app_file_path

        # add empty line at the end of src/app.mts
        echo -e "\nconsole.log();" >>$app_file_path
        sleep 1
        # remove empty lines at the end of src/app.mts
        head -n $(($(wc -l <$app_file_path) - 2)) $app_file_path >temp.txt && mv temp.txt $app_file_path
    done
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
