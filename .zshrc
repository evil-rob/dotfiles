fpath=(/usr/share/zsh/site-functions /usr/share/zsh/functions $fpath)

# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000
setopt extendedglob notify
unsetopt autocd
bindkey -v
# End of lines configured by zsh-newuser-install
# The following lines were added by compinstall
#zstyle :compinstall filename '/home/robert/.zshrc'
#zstyle ':completion:*' menu select
#zstyle ':completion:*:*:gio:*' tag-order 'arguments'

autoload -Uz compinit #bashcompinit
compinit
#bashcompinit
# End of lines added by compinstall

# Manually point to the gnome-keyring SSH socket
#if [ -z "$SSH_AUTH_SOCK" ]; then
#    export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/keyring/ssh"
#fi

source "$HOME/.bash_aliases"
