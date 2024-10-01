#!/bin/bash

# cc0

# now playing notifications with kdialog and playerctl
# please do make patches that make this better, its actually something i use on the daily lol

last_artist=""

cleanup() {
    echo "Cleaning up..."
    rm /dev/shm/np.txt
    exit
}

trap cleanup SIGINT SIGTERM

update_np() {
    song=$(playerctl metadata title)
    artist=$(playerctl metadata artist)
    art=$(playerctl metadata mpris:artUrl)
    if [ -n "$song" ] && [ -n "$artist" ]; then
        if [ "$artist" != "$last_artist" ]; then
            if [ -n "$art" ]; then
                kdialog --title "$artist" --passivepopup "$song" --icon "$art" 3
            else
                kdialog --title "$artist" --passivepopup "$song" 3
            fi
            last_artist=$artist
        fi

        NP="$song - $artist"
        if [ $((RANDOM % 2)) -eq 0 ]; then
            echo "$NP (~^.^)~" > /dev/shm/np.txt
        else
            echo "$NP ~(^.^~)" > /dev/shm/np.txt
        fi
    fi
}

while :
do
    update_np
    sleep 5
done
