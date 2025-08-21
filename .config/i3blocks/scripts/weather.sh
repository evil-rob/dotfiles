#!/bin/bash
# ~/.config/i3blocks/scripts/weather.sh
# Weather widget using Open-Meteo API with click support

# Configuration - Your location coordinates (Burbank, CA area)
LATITUDE="34.1721837"
LONGITUDE="-118.5214278"

# Cache file to avoid too frequent API calls
CACHE_DIR="$HOME/.cache/i3blocks"
CACHE_FILE="$CACHE_DIR/weather_cache"
CACHE_DURATION=600  # 10 minutes

# Create cache directory if it doesn't exist
mkdir -p "$CACHE_DIR"

# Handle click events
if [ ! -z "$BLOCK_BUTTON" ]; then
    case $BLOCK_BUTTON in
        1|3) # Left or right click - open weather forecast
            # Use setsid to create a new session completely detached from swaybar
            setsid -f xdg-open "https://weather.com/weather/today/l/${LATITUDE},${LONGITUDE}" >/dev/null 2>&1
            ;;
        2) # Middle click - refresh weather data
            rm -f "$CACHE_FILE"
            ;;
    esac
    # Don't exit here - continue to display weather data
fi

# Check if cache is valid
if [ -f "$CACHE_FILE" ] && [ $(($(date +%s) - $(stat -c %Y "$CACHE_FILE"))) -lt $CACHE_DURATION ]; then
    cat "$CACHE_FILE"
    exit 0
fi

# Fetch weather data from Open-Meteo
weather_data=$(curl -s "https://api.open-meteo.com/v1/forecast?latitude=${LATITUDE}&longitude=${LONGITUDE}&current_weather=true&temperature_unit=fahrenheit")

if [ $? -ne 0 ] || [ -z "$weather_data" ]; then
    echo "Weather: N/A"
    exit 1
fi

# Parse JSON response
temperature=$(echo "$weather_data" | jq -r '.current_weather.temperature')
weather_code=$(echo "$weather_data" | jq -r '.current_weather.weathercode')

# Convert weather code to icon
case $weather_code in
    0) weather_icon="☀️" ;;           # Clear sky
    1|2|3) weather_icon="⛅" ;;       # Partly cloudy
    45|48) weather_icon="🌫️" ;;       # Fog
    51|53|55) weather_icon="🌦️" ;;    # Drizzle
    56|57) weather_icon="🌧️" ;;       # Freezing drizzle
    61|63|65) weather_icon="🌧️" ;;    # Rain
    66|67) weather_icon="🌨️" ;;       # Freezing rain
    71|73|75) weather_icon="❄️" ;;     # Snow
    77) weather_icon="🌨️" ;;          # Snow grains
    80|81|82) weather_icon="🌦️" ;;    # Rain showers
    85|86) weather_icon="🌨️" ;;       # Snow showers
    95) weather_icon="⛈️" ;;           # Thunderstorm
    96|99) weather_icon="⛈️" ;;       # Thunderstorm with hail
    *) weather_icon="🌡️" ;;           # Unknown
esac

# Format output
output="${weather_icon} ${temperature}°F"

# Save to cache and output
echo "$output" | tee "$CACHE_FILE"
