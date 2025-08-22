#!/bin/sh
# weather.sh
# Weather widget using wttr.in

set -eu

LOCATION="${1-34.1648945,-118.5206919}"

# Cache file to avoid too frequent API calls
CACHE_DIR="$HOME/.cache/i3blocks"
CACHE_FILE="$CACHE_DIR/weather_cache"
CACHE_DURATION=1800  # 30 minutes

# WTTR_PARAMS is space-separated URL parameters, many of which are single characters that can be
# lumped together. For example, "F q m" behaves the same as "Fqm".
if [ -z "${WTTR_PARAMS+x}" ]
then
  # Form localized URL parameters for curl
  { [ -t 1 -a $(tput cols) -lt 125 ]; } 2>/dev/null && WTTR_PARAMS="${WTTR_PARAMS-}n"
  for _token in $( locale LC_MEASUREMENT )
  do
    case $_token in
      1) WTTR_PARAMS="${WTTR_PARAMS-}m" ;;
      2) WTTR_PARAMS="${WTTR_PARAMS-}u" ;;
    esac
  done 2> /dev/null
  unset _token
  export WTTR_PARAMS
fi

wttr() {
  location=$(echo "$1" | tr " " "+")
  [ "$#" -gt 0 ] && shift
  for p in $WTTR_PARAMS "$@"
  do
    [ -n "${args+x}" ] && args="$args --data-urlencode $p" || args="--data-urlencode $p"
  done
  curl -fGsS -H "Accept-Language: ${LANG%_*}" $args --compressed "wttr.in/$location"
}

# Create cache directory if it doesn't exist
mkdir -p "$CACHE_DIR"

if [ -n "${BLOCK_BUTTON+x}" ]
then
    case $BLOCK_BUTTON in
        1|3)
            wttr "$LOCATION.png" | swayimg --fullscreen --scale=fit --config="info.show=no" -
            ;;
        2)
            rm -f "$CACHE_FILE"
            ;;
    esac
fi

# Check if cache is valid
if [ -f "$CACHE_FILE" ] && [ $(($(date +%s) - $(stat -c %Y "$CACHE_FILE"))) -lt $CACHE_DURATION ]
then
    cat "$CACHE_FILE"
    exit 0
fi

# Fetch weather data
weather_data=$(wttr "$LOCATION" "format=2") || { echo "Weather: N/A"; exit 1; }
weather_data=$(echo "$weather_data" | tr "+" " ")

echo "$weather_data" | tee "$CACHE_FILE"
