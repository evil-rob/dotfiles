#!/bin/sh

# Fail fast: -e exits on error, -u treats unset variables as an error.
set -eu

prog_name=$(basename "$0")

# Helper function to print a clean error message
# to stderr and exit with a failure code.
fatal()
{
    echo "[$prog_name] ERROR: $1" >&2
    exit 1
}

# Helper function to perform button actions
do_action()
{
    case "$1" in
        1)
            # Launch terminal and initiate full system upgrade. Hold terminal
            # window open and display a message when package manager exits.
            export PACMAN=$(command -v pacman)
            export MSG="All done! You may now close this window." 
            export ERR_MSG="$(basename $PACMAN) terminated with errors.
    Check /var/log/pacman.log" 
            export PACMAN_OPTS="--sync --refresh --sysupgrade"
            footclient --client-environment --hold --title="pacman" --app-id="pacman" \
                sh -c 'sudo "$PACMAN" $PACMAN_OPTS && echo "$MSG" && exit; echo "$ERR_MSG"; exit 1' \
                && exit

            # If we made it here, the system upgrade was unsuccessful.
            # Print error state to block.
            printf '%s\n' "ERROR" "E" "#FFFF00" "#FF0000"
            exit
            ;;
        2)
            # Manually check for updates. Restart script execution.
            # Unset $button so we do not fall into an infinite loop.
            $HOME/.local/bin/checkupdates.sh >"$UPDATE_FILE"
            unset button
            exec "$0" "$@"
            ;;
        3)
            # Display list of pending updates.
            expac -S "%n\n%v\n%d" $new_packages | yad --title="Update List" \
                --button="Close:0" --width=800 --height=600 --list --no-selection \
                --column="Name" --column="Version" --column="Description" || true
            printf '%s\n' "${full_text#? }" "${short_text}" "${color}" "${background}"
            exit 0
            ;;
        4)
            # Dismiss indicator
            new_packages=""
            ;;
    esac
}

# Display action menu
get_selection()
{
    choice=""
    while [ -z "$choice" ]
    do
        choice=$(yad --width=300 --height=250 \
            --title="Make selection" --list --no-headers \
            --column="ID" --column="Action" \
            "1" "Perform system upgrade" \
            "2" "Manually check for updates" \
            "3" "List pending updates" \
            "4" "Dismiss indicator" \
            --hide-column="1") || choice="0"
    done
    echo "${choice%%|*}"
}

# Configuration:
# Set the update file path. Uses the first script argument ($1), 
# or defaults to ~/.cache/i3blocks/updates if no argument is provided.
UPDATE_FILE="${1:-$HOME/.cache/i3blocks/updates}"

# Validation:
# Verify that the update file actually exists and is a regular file
# before proceeding.
[ -f "$UPDATE_FILE" ] || fatal "Cannot open update file: $UPDATE_FILE"

# Time and Package Processing:
# Calculate how much time since the last successful update.
now=$(date +%s) # Current time in seconds since epoch
last_update=$(date -d "$(head -n1 "$UPDATE_FILE")" +%s) # Reads the timestamp from line 1 of the file and converts to epoch time
age=$((now - last_update)) # Difference in seconds
# Extract the list of pending packages (skips the timestamp on line 1).
new_packages=$(tail -n+2 "$UPDATE_FILE")

# Check if the block was clicked:
[ -z "${button+z}" ] || do_action $(get_selection)

# Look for standard Arch Linux kernel packages in the list.
# If found, set a flag/label to warn that a reboot will likely be needed.
echo "$new_packages" | grep '^linux\(-lts\|-hardened\|-zen\)\?$' >/dev/null 2>&1 && kernel="[new kernel]"

# If there are no packages pending updates, exit successfully. 
# i3blocks will show nothing on the bar.
[ -z "$new_packages" ] && exit 0

# Since notifications are pending, create a notification message.
notification="New updates are available."

# Count how many packages are in the list by counting the lines.
total_packages=$(echo "$new_packages" | wc -l)

# i3blocks expects up to 4 lines of output: Full Text, Short Text, Color, Background.
# waybar expects at least 2 lines of output: Full Text, Tooltip, and optional
# classes separated by newlines.

# --- Line 1: Full Text ---
# The '-' in ${kernel-} prevents the script from
# crashing under 'set -u' if 'kernel' was never set.
[ -z ${WAYBAR_OUTPUT_NAME+z} ] && full_text="[${total_packages}]${kernel-}" || full_text="${total_packages}${kernel-}"

# --- Lines 2 & 4: Short Text and Background Logic ---
# The ${kernel+z} expansion is a safe POSIX way to check
# if 'kernel' is set without triggering 'set -u'.
# Explicitly setting the background in both cases prevents "sticky" colors.
if [ -z "${kernel+z}" ]
then
    # No kernel update: standard package count and a black/default background.
    if [ -z "${WAYBAR_OUTPUT_NAME+z}" ]
    then
        short_text="$total_packages"
        background="" # Empty string will revert to the default background.
    else
        short_text="$total_packages packages pending"
    fi
else
    # Kernel update present: add a 'K' suffix
    # and use a dark blue background as an alert.
    # Also, add restart warning to notification message.
    if [ -z "${WAYBAR_OUTPUT_NAME+z}" ]
    then
        short_text="${total_packages}K"
        background="#000080" # Alert background (Blue)
    else
        short_text="$total_packages packages pending (New kernel)"
        background="notify"
    fi
    notification="${notification}\nRestart required after update for new settings to take effect."
fi

# --- Line 3: Text Color ---
# Set the text color based on how long it's been since the last update check.
if [ "$age" -ge 1814400 ]
then # Red if data is older than 3 weeks (1,814,400 seconds)
    [ -z "${WAYBAR_OUTPUT_NAME+z}" ] && color="#FF0000" || color="alert"
elif [ "$age" -ge 604800 ]
then # Yellow if data is older than 1 week (604,800 seconds) 
    [ -z "${WAYBAR_OUTPUT_NAME+z}" ] && color="#FFFF00" || color="warning" 
else # Green if data is fresh (less than 1 week old) 
    [ -z "${WAYBAR_OUTPUT_NAME+z}" ] && color="#00FF00" || color="fresh" 
fi

# --- Final Output ---
# Print the formatted lines to stdout for i3blocks to read.
printf '%s\n' "$full_text" "$short_text" "$color"
[ -z "${background+z}" ] || echo "$background"
