
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

    scriptOpts.uosc = {
      timeline_style = "bar";
      timeline_line_width = "2";
      timeline_size = "30";
      timeline_border = "1";
      timeline_step = "5";
      timeline_cache = "yes";

      progress = "windowed";
      progress_size = "2";
      progress_line_width = "20";

      controls = "menu,gap,subtitles,<has_many_audio>audio,<has_many_video>video,<has_many_edition>editions,<stream>stream-quality,gap,space,speed,space,shuffle,loop-playlist,loop-file,gap,prev,items,next,gap,fullscreen";
      controls_size = "32";
      controls_margin = "8";
      controls_spacing = "2";

      volume = "right";
      volume_size = "40";
      volume_border = "1";
      volume_step = "1";

      speed_step = "0.1";
      speed_step_is_factor = "no";

      menu_item_height = "36";
      menu_min_width = "360";
      menu_padding = "4";
      menu_type_to_search = "yes";

      top_bar = "always";
      top_bar_size = "40";
      top_bar_controls = "no";
      top_bar_title = "yes";
      top_bar_alt_title_place = "below";
      top_bar_flash_on = "video,audio";

      window_border_size = "1";

      autoload = "yes";
      autoload_types = "video,audio,image";
      shuffle = "no";

      scale = "1";
      scale_fullscreen = "1.3";
      font_scale = "0.8";
      text_border = "1.2";
      border_radius = "4";

      color = "foreground=F0AAB0,foreground_text=120809,background=120809,background_text=F0AAB0,curtain=101419,success=e1bbdc,error=ffb4ab";

      animation_duration = "100";
      click_threshold = "0";
      click_command = "cycle pause; script-binding uosc/flash-pause-indicator";
      flash_duration = "1000";

      proximity_in = "40";
      proximity_out = "120";
      font_bold = "no";
      destination_time = "playtime-remaining";
      time_precision = "0";
      buffered_time_threshold = "60";
      autohide = "yes";
      pause_indicator = "flash";

      stream_quality_options = "4320,2160,1440,1080,720,480,360,240,144";

      chapter_ranges = "openings:30abf964,endings:30abf964,ads:c54e4e80";
      chapter_range_patterns = "openings:オープニング;endings:エンディング";

      languages = "slang,en";
      adjust_osd_margins = "yes";
    };
  };
}
