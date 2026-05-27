#!/bin/sh

[ -z ${button+z} ] || yad --html --browser --uri="https://wttr.in/" --width=920 --height=640 --button="Close:0"

CACHE="${1-$HOME/.cache/i3blocks/weather}"
rf=$(mktemp -u ref_date_XXXXXXXXXX)
touch -d "1 day ago" "$rf"

if [ "$CACHE" -ot "$rf" ]
then
    echo "Weather Data N/A"
    echo "N/A"
else
    read -r weather temperature wind < "$CACHE"
    printf "%s\n" "$weather  $temperature $wind" "$weather"
fi

rm -f "$rf"
