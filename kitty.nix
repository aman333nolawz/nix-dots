{ config, pkgs, lib, ... }:
{
  programs.kitty = {
    enable = true;
    themeFile = "tokyo_night_night";
    font = {
      name = "CaskaydiaCove NF";
      size = 12;
    };
    settings = {
      disable_ligatures = "never";
      window_padding_width = 20;
      cursor_trail = 1;
      allow_remote_control = true;
      tab_bar_edge = "bottom";
      tab_bar_style = "powerline";
      tab_powerline_style = "slanted";
      tab_title_template = "{title}{' :{}:'.format(num_windows) if num_windows > 1 else ''}";
      bold_font = "auto";
      italic_font ="auto";
      bold_italic_font = "auto";
    };
    keybindings = {
      "ctrl+shift+t" = "new_tab_with_cwd";
    };
  };
}
