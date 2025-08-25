#!/bin/bash
# ~/.config/i3blocks/scripts/battery.sh
# Battery indicator with percentage and status

# Find battery path
battery_path="/sys/class/power_supply/BAT0"
if [ ! -d "$battery_path" ]; then
    battery_path="/sys/class/power_supply/BAT1"
fi

if [ ! -d "$battery_path" ]; then
    echo "🔌 AC"
    exit 0
fi

# Read battery information
capacity=$(cat "$battery_path/capacity" 2>/dev/null)
status=$(cat "$battery_path/status" 2>/dev/null)

if [ -z "$capacity" ]; then
    echo "🔋 N/A"
    exit 0
fi

# Determine battery icon based on charge level and status
if [ "$capacity" -ge 90 ]; then
    battery_icon=""
elif [ "$capacity" -ge 75 ]; then
    battery_icon=""
elif [ "$capacity" -ge 50 ]; then
    battery_icon=""
elif [ "$capacity" -ge 25 ]; then
    battery_icon=""
elif [ "$capacity" -ge 10 ]; then
    battery_icon=""
else
    battery_icon="🪫"
fi

case $status in
    "Charging")
        status_icon=" "
        ;;
    "Full")
        status_icon=" "
        ;;
    "Discharging"|"Not charging")
        status_icon=""
        ;;
    *)
        battery_icon="🔋"
        status_icon=""
        ;;
esac

# Color coding based on battery level for low battery warning
if [ "$capacity" -le 15 ] && [ "$status" != "Charging" ]; then
    echo "${battery_icon} ${capacity}%${status_icon}"
    echo ""  # Short text (same as full text)
    echo "#FF0000"  # Red color for critical battery
elif [ "$capacity" -le 30 ] && [ "$status" != "Charging" ]; then
    echo "${battery_icon} ${capacity}%${status_icon}"
    echo ""
    echo "#FFA500"  # Orange for low battery
else
    echo "${battery_icon} ${capacity}%${status_icon}"
fi
