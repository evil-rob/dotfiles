#!/bin/bash

# Updates script for Waybar
# Shows available package updates for Arch Linux

CACHE_FILE="$HOME/.cache/waybar/updates.json"
UPDATE_INTERVAL=3600  # 1 hour

# Create cache directory
mkdir -p "$(dirname "$CACHE_FILE")"

loadUpdatesFromCache() {
    # Load updates data from cache if recent enough
    if [ -s "$CACHE_FILE" ]; then
        cache_time=$(jq -r '.time // 0' "$CACHE_FILE" 2>/dev/null || echo 0)
        current_time=$(date +%s)
        
        if [ $((current_time - cache_time)) -lt $UPDATE_INTERVAL ]; then
            jq . "$CACHE_FILE" 2>/dev/null
            return 0
        fi
    fi
    return 1
}

getNewUpdatesData() {
    # Check for available updates
    updates_count=$(checkupdates 2>/dev/null | wc -l)
    current_time=$(date +%s)
    
    # Cache the result
    echo "{\"time\": $current_time, \"updates\": $updates_count}" > "$CACHE_FILE"
    echo "{\"time\": $current_time, \"updates\": $updates_count}"
}

# Load cached data or get fresh data
updates_data=$(loadUpdatesFromCache || getNewUpdatesData)
packages=$(echo "$updates_data" | jq -r '.updates // 0')

# Output for Waybar
if [ "$packages" -gt 0 ]; then
    if [ "$packages" -eq 1 ]; then
        tooltip="1 package update available"
    else
        tooltip="$packages package updates available"
    fi
    echo "{\"text\": \" $packages\", \"tooltip\": \"$tooltip\"}"
else
    # Hide completely when no updates (empty output)
    echo ""
fi
