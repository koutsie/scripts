#!/bin/sh
# cc0
# Toggle the "Hardware FPS Meter" for Acer mmonitors (mine is a VG240Y S)
# obviously edit the below values to match your monitors one.
# info from vitalised: https://github.com/VITALISED/acer_mccs - shoutouts
input=$(ddcutil getvcp --noverify --display 2 0xE1 --ddc-checks-async-min 2)
sl_part="${input##*sl=}"
sl_value="${sl_part%%,*}"
sl_value="${sl_value// /}"
if [ "$sl_value" == "0x01" ]; then
    result=0
elif [ "$sl_value" == "0x00" ]; then
    result=1
else
    result="Unknown"
fi
ddcutil setvcp --noverify --display 2 0xE0 5 0xE1 "$result" --ddc-checks-async-min 2