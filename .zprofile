[[ -f "$HOME/.profile" ]] && source "$HOME/.profile"
[[ -f "$HOME/.zshrc" ]] && source "$HOME/.zshrc"

#if [[ -n "$DESKTOP_SESSION" ]]
#then
#    export $(gnome-keyring-daemon --start)
#fi

if [[ -z "$DISPLAY" && "$XDG_VTNR" -eq 1 ]]
then
    #exec sway
    true
fi
