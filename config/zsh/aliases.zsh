alias man="batman"
alias cat="bat"
alias grep="rg"
alias find="fd"
alias ls="eza --icons=always"
alias vim="nvim"
alias v="nvim"
alias wget="aria2c"

# Colored output
export CALCURSE_PAGER="glow --pager"
export LESS='-R --use-color -Dd+r$Du+b'
alias ip='ip -color=auto'
alias grep='grep --color=auto'
alias diff='diff --color=auto'

# Dotfiles config
alias dots='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
alias reload="exec zsh"

alias adb_set_proxy="adb shell settings put global http_proxy $(ip -o  -4 addr show wlo1 | awk '{print $4}' | sed 's/\/.*//g'):8080"
alias adb_unset_proxy="adb shell settings put global http_proxy :0"
