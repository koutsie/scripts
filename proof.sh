#!/bin/sh

line() {
    printf '%*s\n' "22" '' | tr ' ' '-'
}

box() {
    line
    echo "[ $* ]"
    line
}

yle=$(curl -s "https://feeds.yle.fi/uutiset/v1/recent.rss?publisherIds=YLE_NEWS" | grep -Eo '<title>.*</title>' | head -n 2 | tail -n 1 | sed 's/<[^>]*>//g' | tr '[:upper:]' '[:lower:]')
kernel=$(uname -srv | tr '[:upper:]' '[:lower:]')
ntp_servers=$(timedatectl show-timesync --all | grep 'FallbackNTPServers=' | cut -d'=' -f2 | tr '[:upper:]' '[:lower:]')
[ -z "$ntp_servers" ] && ntp_servers="ntp'dnt"
current_time=$(date | tr '[:upper:]' '[:lower:]')
usb_devices=$(lsusb | awk '{print $7, $8, $9, $10}' | tr '[:upper:]' '[:lower:]')
usb_hash=$(echo "$usb_devices" | md5sum | awk '{print substr($1,1,8)}')
username=$(whoami | tr '[:upper:]' '[:lower:]')
home_folder=$(eval echo "~$username" | tr '[:upper:]' '[:lower:]')
home_folder_hash=$(echo "$home_folder" | md5sum | awk '{print substr($1,1,8)}')
root_disk=$(df / | tail -1 | awk '{print $1}' | tr '[:upper:]' '[:lower:]')
root_disk_hash=$(echo "$root_disk" | md5sum | awk '{print substr($1,1,8)}')
script_path=$(
    cd "$(dirname "$0")"
    pwd -P
)/$(basename "$0")
script_hash=$(md5sum "$script_path" | awk '{print substr($1,1,8)}')
info_hash=$(echo "$username$home_folder_hash$root_disk_hash$script_hash" | md5sum | awk '{print substr($1,1,8)}')

{
    box "proof.txt for $(hostname | tr '[:upper:]' '[:lower:]')"
    echo
    printf "%-20s %s\n" "Latest YLE News:" "$yle"
    printf "%-20s %s\n" "Kernel Info:" "$kernel"
    printf "%-20s %s\n" "NTP Servers:" "$ntp_servers"
    printf "%-20s %s\n" "Current Time:" "$current_time"
    printf "%-20s %s\n" "USB Hash:" "$usb_hash"
    printf "%-20s %s\n" "Username:" "$username"
    printf "%-20s %s\n" "Home Folder Hash:" "$home_folder_hash"
    printf "%-20s %s\n" "Root Disk Hash:" "$root_disk_hash"
    printf "%-20s %s\n" "Script Hash:" "$script_hash"
    printf "%-20s %s\n" "User Info Hash:" "$info_hash"
    echo
    line
} >/dev/shm/hello.txt

cat /dev/shm/hello.txt
