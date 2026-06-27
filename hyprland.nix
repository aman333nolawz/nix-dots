{ lib, ... }:
{
  services.hypridle.enable = true;
  wayland.windowManager.hyprland = {
    enable = true;
    systemd.enable = false;
    extraConfig = ''
    require("keybinds")
    require("windowrules")
    '';


    settings = {
      mod = {
        _var = "SUPER";
      };

      config = {
        xwayland = {
          force_zero_scaling = true;
        };
        general = {
          gaps_out = 10;
        };
        decoration = {
          rounding = 10;
          active_opacity = 1.0;
          inactive_opacity = 0.9;
          blur = {
            enabled = true;
            size = 10;
            passes = 2;
          };
        };
        input = {
          touchpad = {
              disable_while_typing = false;
              natural_scroll = true;
          };
        };
      };

      gesture = {
        fingers = 3;
        direction = "horizontal";
        action = "workspace";
      };


      on = {
        _args = [
          "hyprland.start"
         (lib.generators.mkLuaInline ''
         function()
           hl.exec_cmd("hyprshell run -q")
           hl.exec_cmd("noctalia-shell")
         end'')
       ];
      };

    };
  };
}
