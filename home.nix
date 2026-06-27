{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ./hyprland.nix
    ./zsh.nix
    ./kitty.nix
    ./theming.nix
    ./nvim.nix
    ./ncmpcpp.nix
    ./noctalia.nix
    ./spotify.nix
  ];

  home.username = "nolawz";
  home.homeDirectory = "/home/nolawz";
  home.stateVersion = "26.05";

  sops = {
    defaultSopsFile = ./secrets/secrets.yaml;
    age.keyFile = "/home/nolawz/.config/sops/age/keys.txt";
    secrets.mopidy-scrobbler = {};
  };

  home.packages = with pkgs; [
    hypridle
    p7zip
    aria2
    unzip
    awww
    deluge
    mpv
    mpc
    mopidy
    yt-dlp
    ncmpcpp
    vimiv-qt
    rofi
    matugen
    auto-cpufreq
    nbfc-linux
    quickshell
    ripgrep
    nemo-with-extensions
    nwg-displays
    starship
    btop
    bat
    eza
    playerctl
    grim
    slurp
    uv
    wl-clipboard
    cliphist
    satty
    hyprpicker
    pavucontrol
    obsidian
    sioyek
    genymotion
    android-tools
    caido-desktop
    caido-cli

    nerd-fonts.caskaydia-cove
    nerd-fonts.jetbrains-mono

    file
    zsteg
    steghide
    exiftool
    hexedit
    xxd
    foremost
    stegsolve

    openssl
    gdb
    codex
    opencode
    rustup
    jdk
    nodejs
    prisma
    bun
    gcc
    gnumake
    libcap
    go
    typst
    tree-sitter
    pwntools
    pwninit
    patchelf
    (python3.withPackages (python-pkgs: with python-pkgs; [
      ropper
      requests
      numpy
    ]))
  ];

  programs.git = {
    enable = true;
    settings.user.name = "aman333nolawz";
    settings.user.email = "amananudhiu@gmail.com";
    settings = {
      init.defaultBranch = "main";
    };
  };
  programs.gh = {
    enable = true;
    gitCredentialHelper = {
      enable = true;
    };
  };

  services.awww.enable = true;
  services.mpris-proxy.enable = true;
  services.udiskie = {
    enable = true;
    settings = {
        # workaround for
        # https://github.com/nix-community/home-manager/issues/632
        program_options = {
            # replace with your favorite file manager
            file_manager = "${pkgs.nemo-with-extensions}/bin/nemo";
        };
    };
  };


  programs.nyaa.enable = true;
  programs.sioyek = {
    enable = true;
    config = {
      background_color = "1.0 1.0 1.0";
      startup_commands = [
        "toggle_visual_scroll"
        "toggle_dark_mode"
      ];
      text_highlight_color = "1.0 0.0 0.0";
    };
  };

  xdg.configFile = {
    "zsh".source = ./config/zsh;
    "nvim".source = ./config/nvim;
    "mpv".source = ./config/mpv;
    "nyaa".source = ./config/nyaa;
    "pwntools".source = ./config/pwntools;
    "electron-flags.conf".source = ./config/electron-flags.conf;
    "hypr/keybinds.lua".source = ./config/hypr/keybinds.lua;
    "hypr/windowrules.lua".source = ./config/hypr/windowrules.lua;
    "hypr/hypridle.conf".source = ./config/hypr/hypridle.conf;
    "spotify-flags.conf".text = ''
      --enable-features=UseOzonePlatform
      --ozone-platform=wayland
      --enable-wayland-ime
    '';
  };

  home.file = {
    ".local/share/streams.txt".source = ./share/streams.txt;
    ".local/bin/" = {
      source = ./bin;
      recursive = true;
      executable = true;
    };
    ".gdbinit".text = ''
      source /home/nolawz/pwndbg/gdbinit.py
    '';
  };

  home.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    EDITOR = "nvim";
    TERMINAL = "kitty";
    EXPLORER = "nemo";

    GTK_THEME = "Tokyonight-Dark";
    GTK_APPLICATION_PREFER_DARK_THEME = "1";
    QT_STYLE_OVERRIDE = "gtk3";
    QT_QPA_PLATFORMTHEME = "gtk3";

    LC_ALL = "en_US.UTF-8";
    LANG = "en_US.UTF-8";
    LANGUAGE = "en_US.UTF-8";

    PWNDBG_NO_AUTOUPDATE = 1;
  };

  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/.cargo/bin"
  ];


  programs.home-manager.enable = true;
}
