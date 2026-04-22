#!/bin/sh

# Checks if updates are available. First line is a time stamp for the last
# successful update. Remaining lines is a list of new packages available.
# If the -j flag is supplied as the first argument, output will be in JSON.
# If a path is supplied, an existing database will be used instead of pulling
# down a fresh copy.

set -eu

PROG_NAME=$(basename "$0")
PREFIX="checkup-db-$USER"
DBPath="/var/lib/pacman"

if [ "${1-}" == "-j" ]
then
    JSON=""
    shift
fi

if [ -z "${1:+z}" ]
then
    # $1 is empty or unset
    # Look in $TMPDIR to see if $PREFIX.* exists
    set -- "${TMPDIR:-/tmp}/$PREFIX".*
    [ -d "$1" ] && CHECKUPDATES_DB="$1" || CHECKUPDATES_DB="$(mktemp --directory --tmpdir "$PREFIX".XXXXXXXXXX)"
else
    # $1 is set to previous CHECKUPDATES_DB
    CHECKUPDATES_DB="$1"
fi

if [ ! -d "$CHECKUPDATES_DB" ] 
then
    echo "$CHECKUPDATES_DB does not exist" >&2
    exit 1
fi

last_update=$(awk '/starting full system upgrade/ {f=1} f && /transaction completed/ {s=$1; f=0} END {print s}' /var/log/pacman.log | tr -d '[]')
[ -h "$CHECKUPDATES_DB/local" ] || ln -s "$DBPath/local" "$CHECKUPDATES_DB" || exit 2
fakeroot pacman -Sy --dbpath "$CHECKUPDATES_DB" --logfile /dev/null --disable-sandbox >&2 #>/dev/null 2>&1

# Generate list of out of date packages. Pacman will exit with failure if
# no packages match the query, i.e. nothing is out of date. Send a desktop
# notification if new updates are available.
new_packages=$(pacman -Qqu --dbpath "$CHECKUPDATES_DB") && \
    notify-send "$PROG_NAME" "$(echo "$new_packages"|wc -l) updates available."
if [ -n "${JSON+z}" ]
then
    # JSON flag was passed so output as JSON
    #echo "$new_packages" | jq --raw-input --slurp --compact-output '{last_update: "'"$last_update"'", new_packages: split("\n") | map(select(length > 0))}'
    printf '{"last_update": "%s", "new_packages": [' $last_update
    prefix=""
    for package in $new_packages
    do
        printf '%s"%s"' "$prefix" "$package"
        prefix=", "
    done
    echo "]}"
    unset prefix
else
    # Plain output. First line shout be last_update.
    printf "%s\n" "$last_update" "$new_packages"
fi
