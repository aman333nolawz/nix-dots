# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, inputs, ... }:
let
  tsushimaTheme = pkgs.stdenv.mkDerivation {
    pname = "grub-of-tsushima-white";
    version = "1.0";

    src = inputs.grub-of-tsushima;

    installPhase = ''
      mkdir -p $out
      cp -r grub-of-tsushima-white/* $out/
    '';
  };
in
{
  imports =
    [
      ./hardware-configuration.nix
    ];

  boot.loader = {
    efi.canTouchEfiVariables = true;

    grub = {
      enable = true;
      efiSupport = true;
      device = "nodev";
      useOSProber = true;
      gfxpayloadEfi = "keep";
      theme = tsushimaTheme;
    };
  };

  networking.hostName = "nolawz-pc"; 
  networking.networkmanager.enable = true;

  programs.gpu-screen-recorder.enable = true;
  time.timeZone = "Asia/Kolkata";

  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;
  };

  services.displayManager.sddm = {
    enable = true;
    wayland = {
      enable = true;
      compositor = "kwin";
    };
    settings = {
      Theme = {
        CursorTheme = "Bibata-Modern-Ice";
        CursorSize = 24;
      };
    };
  };


  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };


	fonts.fontconfig.enable = true;
  fonts.packages = with pkgs; [
    roboto
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    liberation_ttf
  ];

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  environment.shells = with pkgs; [ zsh ];
  users.defaultUserShell = pkgs.zsh;
  programs.zsh.enable = true;

  virtualisation.docker = {
    enable = true;
  };

  users.users."nolawz" = {
    isNormalUser = true;
    description = "Nolawz";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    packages = with pkgs; [];
  };

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = false;
  };
  services.blueman.enable = true;
  services.tuned.enable = true;
  services.udisks2.enable = true;
  services.tailscale.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    neovim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    kitty
    git
    bibata-cursors
    hyprshell
    man
    man-db
    netcat-gnu

    mopidy-mpd
    mopidy-local
    mopidy-scrobbler

    age
    sops
    bluez
    brightnessctl
    xdg-desktop-portal-hyprland
    upower
    libnotify
    python3
    polkit
    ffmpeg
    qt6.qtbase
    qt6.qtmultimedia
    imagemagick
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
    inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
    inputs.curd.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  virtualisation.waydroid.enable = true;

 programs.steam = {
   enable = true;
   remotePlay.openFirewall = true;
   dedicatedServer.openFirewall = true;
 };

 hardware.graphics = {
   enable = true;
   enable32Bit = true;
 };

 programs.gamescope = {
   enable = true;
   enableWsi = true;
   capSysNice = false;
 };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  services.logind.settings.Login.HandlePowerKey = "ignore";


  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "26.05"; # Did you read the comment?

}
