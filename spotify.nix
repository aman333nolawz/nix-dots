{ pkgs, inputs, ... }:

{
  programs.spicetify =
  let
    spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
  in
  {
    enable = true;
    enabledExtensions = with spicePkgs.extensions; [
      adblock
      lastfm
      shuffle
      spicyLyrics
      coverAmbience
      autoVolume
      catJamSynced
    ];

    wayland = true;
    theme = spicePkgs.themes.comfy;
    colorScheme = "catppuccin-mocha";
  };
  
  xdg.desktopEntries.spotify = {
    name = "Spotify";
    genericName = "Music Player";
    exec = "env -u DISPLAY spotify %U";
    icon = "spotify";
    terminal = false;
    categories = [ "AudioVideo" "Music" "Player" ];
    mimeType = [ "x-scheme-handler/spotify" ];
  };
}
