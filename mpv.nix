
{ config, pkgs, lib, ... }:
{
  programs.mpv = {
    enable = true;

    scripts = with pkgs.mpvScripts; [
      uosc
      thumbfast
    ];

    config = {
      # Playback
      fullscreen = "yes";
      hwdec = "auto";
      hwdec-codecs = "all";
      "save-position-on-quit" = "";
      "resume-playback" = "";
      "keep-open" = "";

      # Appearance
      osc = "no";
      "osd-bar" = "no";
      border = "no";

      # Subtitles
      "sub-border-style" = "opaque-box";
      "sub-outline-color" = "#99000000";
      "sub-outline-size" = 5;
      "sub-line-spacing" = 15;

      # Color management
      "target-colorspace-hint" = "no";
    };
  };
}
