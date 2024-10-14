#!/bin/bash

# cc0

# a horrible horrible script.
# depends on skdump (aka libatasmart)

CYAN=$(tput setaf 39)
ORANGE=$(tput setaf 214)
LIGHT_RED=$(tput setaf 9)
LIGHT_GREEN=$(tput setaf 10)

NC=$(tput sgr0)

order=("Model" "Space" "Power Cycles" "Powered On Hours" "Average Powered On" "Disk Health")

format_output() {
    local value="$1"
    local key="$2"

    case $value in
    yes | GOOD) echo "${LIGHT_GREEN}$value${NC}" ;;
    BAD) echo "${LIGHT_RED}$value${NC}" ;;
    *)
        echo "$value"
        ;;
    esac
}

get_disk_info() {
    local disk=$1
    local output
    output=$(sudo skdump "$disk" 2>/dev/null)
    if [[ -z "$output" ]]; then
        return 1
    fi
    declare -A info
    info[Model]=$(echo "$output" | grep "Model" | awk -F ': ' '{print $2}')
    info[Space]=$(echo "$output" | grep "Size" | awk -F ': ' '{print $2}' | awk '{printf "%.2f GB\n", $1/1024}')
    info["Power Cycles"]=$(echo "$output" | grep "Power Cycles" | awk -F ': ' '{print $2}')
    info["Powered On Hours"]=$(echo "$output" | grep "Powered On:" | awk -F ': ' '{print $2}')
    info["Average Powered On"]=$(echo "$output" | grep "Average Powered On Per Power Cycle" | awk -F ': ' '{print $2}')
    info["Disk Health"]=$(echo "$output" | grep "SMART Disk Health" | awk -F ': ' '{print $2}')
    for key in "${order[@]}"; do
        echo "${info[$key]}"
    done
}

declare -A max_widths
for key in "${order[@]}"; do
    max_widths[$key]=${#key}
done

# get disk infor for all the disks
# COMMENT: Mon Oct 14 01:14:32 PM EEST 2024
# There should probably be a better, "more" posix way to do this but
# i'm fucking lazy and honestly - it works.
# - kouts
mapfile -t disks < <(lsblk -ndo name | grep -E '^sd|^nvme|^loop|^sr|^vda')
for disk in "${disks[@]}"; do
    readarray -t disk_info < <(get_disk_info "/dev/$disk")
    disk_name="/dev/$disk"
    disk_name_len=${#disk_name}
    if ((disk_name_len > max_widths[Model])); then
        max_widths[Model]=$disk_name_len
    fi
    for i in "${!order[@]}"; do
        key="${order[$i]}"
        width=${#disk_info[$i]}
        if ((width > ${max_widths[$key]})); then
            max_widths[$key]=$width
        fi
    done
done

# align ur rows so all our disk names can fit properly
printf "${CYAN}%-$((${max_widths[Model]} + 2))s${NC}" "Disk Name"
for key in "${order[@]}"; do
    printf "${CYAN}%-$((${max_widths[$key]} + 2))s${NC}" "$key"
done
echo

for disk in "${disks[@]}"; do
    readarray -t disk_info < <(get_disk_info "/dev/$disk")
    disk_name="/dev/$disk"
    printf "${ORANGE}%-$((${max_widths[Model]} + 2))s${NC}" "$disk_name"
    for i in "${!order[@]}"; do
        key="${order[$i]}"
        value=$(format_output "${disk_info[$i]}" "$key")
        printf "%-$((${max_widths[$key]} + 2))s" "$value"
    done
    echo
done
