{ inputs, pkgs, ... }:
{
  gtk = {
    enable = true;
    theme = {
      name = "adw-gtk3-dark";
      package = pkgs.adw-gtk3;
    };

    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.catppuccin-papirus-folders.override {
        flavor = "mocha";
        accent = "lavender";
      };
    };

    cursorTheme = {
      name = "Catppuccin-Mocha-Light-Cursors";
      package = pkgs.catppuccin-cursors.mochaLight;
    };

    gtk3 = {
      extraConfig.gtk-application-prefer-dark-theme = true;
    };
  };

  dconf.settings = {
    "org/gtk/settings/file-chooser" = {
      sort-directories-first = true;
    };

    # GTK4 Setup
    "org/gnome/desktop/interface" = {
      gtk-theme = "adw-gtk3-dark";
      color-scheme = "prefer-dark";
    };
  };


  qt = {
    enable = true;
    platformTheme = {
      name = "gtk3";
    };
    style.name = "gtk3";
  };

  home.pointerCursor = {
    enable = true;
    name = "Catppuccin-Mocha-Light-Cursors";
    package = pkgs.catppuccin-cursors.mochaLight;
  };
}
