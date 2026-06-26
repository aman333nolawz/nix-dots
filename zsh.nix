{ config, pkgs, lib, ... }:
{
  programs.zsh = {
    enable = true;

    enableCompletion = true;
    autocd = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    initContent = ''
ZSH=~/.config/zsh

for file in $ZSH/lib/*;
do
    source $file
done

for plugin in $ZSH/plugins/*;
do
    source $plugin
done

source $ZSH/aliases.zsh
# source $ZSH/prompt.zsh

complete -F _complete_alias dots
complete -F _complete_alias ls

eval "$(starship init zsh)"
    '';


    history.size = 10000;
  };
}
