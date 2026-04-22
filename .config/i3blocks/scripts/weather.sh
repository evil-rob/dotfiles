#!/bin/sh

. $HOME/.local/bin/wttr.sh

[ -z ${button+z} ] || wttr -H | yad --html --width=920 --height=640 --button="Close:0"

cat "${1-$HOME/.cache/i3blocks/weather}"
