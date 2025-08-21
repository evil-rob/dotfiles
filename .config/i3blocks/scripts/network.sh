#!/bin/bash
# ~/.config/i3blocks/scripts/network.sh
# Network widget showing WiFi connection and signal strength with click support

# Handle click events
if [ ! -z "$BLOCK_BUTTON" ]; then
    case $BLOCK_BUTTON in
        1|3) # Left or right click - open WiFi network list
            # Use nmtui-connect for quick WiFi connection
            if command -v nmtui-connect &> /dev/null; then
                footclient -e nmtui-connect &
            elif command -v nmtui &> /dev/null; then
                # Fallback to full nmtui
                footclient -e nmtui &
            elif command -v nm-connection-editor &> /dev/null; then
                # NetworkManager GUI
                nm-connection-editor &
            elif command -v gnome-control-center &> /dev/null; then
                # GNOME Settings
                gnome-control-center wifi &
            elif command -v iwgtk &> /dev/null; then
                # iwd GTK frontend
                iwgtk &
            else
                # Fallback: try to open system settings
                xdg-open "settings://network" &
            fi
            ;;
        2) # Middle click - refresh network info and reconnect if needed
            # Toggle WiFi off and on to refresh connection
            if command -v nmcli &> /dev/null; then
                nmcli radio wifi off && sleep 1 && nmcli radio wifi on
            fi
            ;;
    esac
    exit 0
fi

# Check if connected to WiFi
wifi_interface=$(iw dev | awk '$1=="Interface"{print $2}' | head -1)

if [ -z "$wifi_interface" ]; then
    echo " No WiFi"
    exit 0
fi

# Get WiFi information
wifi_info=$(iw dev "$wifi_interface" link)
connection_status=$(echo "$wifi_info" | grep "Connected to")

if [ -z "$connection_status" ]; then
    # Check if ethernet is connected
    ethernet_status=$(cat /sys/class/net/*/operstate | grep -c "up")
    if [ "$ethernet_status" -gt 1 ]; then  # More than 1 means ethernet is likely up (lo is always up)
        echo " Ethernet"
    else
        echo " Disconnected"
    fi
    exit 0
fi

# Get SSID
ssid=$(echo "$wifi_info" | grep "SSID" | awk '{print $2}')

# Get signal strength
signal_info=$(iw dev "$wifi_interface" station dump)
signal_strength=$(echo "$signal_info" | grep "signal:" | awk '{print $2}' | head -1)

if [ -z "$signal_strength" ]; then
    # Alternative method using /proc/net/wireless
    signal_strength=$(awk "/$wifi_interface/ {print \$3}" /proc/net/wireless | sed 's/\.//')
    if [ ! -z "$signal_strength" ]; then
        # Convert from quality to approximate dBm (this is rough)
        signal_strength=$((signal_strength - 100))
    fi
fi

# Format SSID (truncate if too long)
if [ ${#ssid} -gt 12 ]; then
    ssid="${ssid:0:9}…"
fi

# Output format
if [ ! -z "$signal_strength" ]; then
    echo " ${ssid} (${signal_strength}dBm)"
else
    echo " ${ssid}"
fi
