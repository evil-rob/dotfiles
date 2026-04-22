#!/bin/sh
# vim: set tabstop=2 shiftwidth=2 expandtab:

set -eu
name=$(basename "$0" | cut -d. -f1)

enumerate_smb()
{
  for host in $(avahi-browse -tr _smb._tcp | sed -n '/^\s*hostname = \[\(.*\)\]/s//\1/p' | uniq)
  do
    cache_file="$HOME/.cache/$(echo -n "$host" | sha1sum | xxd -p -r | base32 | tr "[:upper:]" "[:lower:]")"
    if [ -s "$cache_file" ] && [ $(stat -c %Y "$cache_file") -ge $(date -d '24 hours ago' +%s) ]
    then
      cat "$cache_file"
      continue
    fi
    smbclient -L "//$host" -A "$HOME/.config/win-credentials" | awk '$2=="Disk" { print "smb://'"$host"'/"$1 }' | tee "$cache_file"
  done
}

enumerate_sftp()
{
  avahi-browse -tr _sftp._tcp | sed -n '/^\s*hostname = \[\(.*\)\]/s//sftp:\/\/\1\//p' | uniq
}

enumerate_mtp()
{
  gio mount -li | sed -n '/^\s*activation_root=mtp:\/\//s//mtp:\/\//p'
}

fatal()
{
  echo "Fatal error: $1" >&2
  exit 1
}

choice=$(printf "%s\n" $(enumerate_mtp) $(enumerate_sftp) $(enumerate_smb) | wmenu -l8 2>/dev/null)
gio mount "$choice" || fatal "Failed to mount $choice"
gio info "$choice" | sed -n '/^local path: /s///p'
