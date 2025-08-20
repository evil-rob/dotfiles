#!/bin/bash

# Weather script for Waybar using open-meteo.com (no API key required)

CACHE_FILE="$HOME/.cache/waybar/weather.json"
LATITUDE="34.1721837"
LONGITUDE="-118.5214278"
QUERY="https://api.open-meteo.com/v1/forecast?latitude=$LATITUDE&longitude=$LONGITUDE&current=temperature_2m,weather_code,is_day&timezone=auto&forecast_days=1&timeformat=unixtime&wind_speed_unit=mph&temperature_unit=fahrenheit&precipitation_unit=inch"
UPDATE_INTERVAL=14400  # 4 hours

# Create cache directory
mkdir -p "$(dirname "$CACHE_FILE")"

loadWeatherFromCache() {
    # Load weather JSON data from file if exists and validate data
    [ -s "$1" ] && jq . "$1" 2>/dev/null
}

getNewWeatherData() {
    # Get new weather JSON data from server and cache it
    curl -s "$QUERY" | tee "$CACHE_FILE" | jq . 2>/dev/null || {
        jq -cn '{
            current_units: {
                time: "unixtime",
                interval: "seconds", 
                temperature_2m: "°F",
                weather_code: "wmo code"
            },
            current: {
                time: (now|floor),
                interval: 900,
                temperature_2m: 0,
                weather_code: -1,
                is_day: 1
            }
        }'
    }
}

# Load cached weather or get fresh data
weather=$(loadWeatherFromCache "$CACHE_FILE" || getNewWeatherData)

# Check if data is stale
refreshTime=$(echo "$weather" | jq ".current | [.time, .interval] | add - now | floor" 2>/dev/null || echo "-1")
[ "$refreshTime" -lt 0 ] && weather=$(getNewWeatherData)

# Parse weather data
code=$(echo "$weather" | jq -r '.current.weather_code // -1')
temp_raw=$(echo "$weather" | jq -r '.current.temperature_2m // 0')
temp_unit=$(echo "$weather" | jq -r '.current_units.temperature_2m // "°F"')
temperature=$(printf "%.1f%s" "$temp_raw" "$temp_unit")
is_day=$(echo "$weather" | jq -r '.current.is_day // 1')

# Set weather icon based on WMO weather code and day/night
case "$code" in
    0|1)    # Clear/Mostly clear
        [ "$is_day" -eq 1 ] && icon="" || icon=""
        desc="Clear"
        ;;
    2)      # Partly cloudy  
        [ "$is_day" -eq 1 ] && icon="" || icon=""
        desc="Partly Cloudy"
        ;;
    3)      # Overcast
        icon=""
        desc="Overcast"
        ;;
    4[5-8]) # Fog
        icon=""
        desc="Fog"
        ;;
    5[1-7]) # Drizzle
        [ "$is_day" -eq 1 ] && icon="" || icon=""
        desc="Drizzle"
        ;;
    6[1-7]) # Rain
        icon=""
        desc="Rain"
        ;;
    9[5-9]) # Thunderstorm
        icon=""
        desc="Thunderstorm"
        ;;
    *)      # Unknown/Error
        icon=""
        desc="Unknown"
        ;;
esac

# Handle error case
if [ "$code" = "-1" ] || [ "$temp_raw" = "0" ]; then
    echo '{"text": " --", "tooltip": "Weather data unavailable"}'
else
    tooltip="$desc\\nTemperature: $temperature"
    echo "{\"text\": \"$icon $temperature\", \"tooltip\": \"$tooltip\"}"
fi
