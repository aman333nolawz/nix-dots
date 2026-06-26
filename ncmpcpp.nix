{ config, pkgs, ... }:
{
  services.mopidy = {
    enable = true;
    extensionPackages = with pkgs; [ mopidy-mpd mopidy-local mopidy-scrobbler ];
    extraConfigFiles = [ config.sops.secrets.mopidy-scrobbler.path ];
    settings = {
      mpd.enabled = true;
      core.restore_state = true;
      local = {
        enabled = true;
        media_dir = "/home/nolawz/Music/";
      };
    };
  };

  programs.ncmpcpp = {
    enable = true;

    settings = {
      # --- connection (mopidy-mpd) ---
      mpd_host                              = "127.0.0.1";
      mpd_port                              = 6600;
      mpd_connection_timeout                = 5;
      mpd_crossfade_time                    = 2;

      # --- ui layout ---
      user_interface                        = "alternative";
      alternative_header_first_line_format  = "$b$5{%t}|{%f}$/b - $6%a";
      alternative_header_second_line_format = "$b$8{%b}$/b - $4{%y}";
      playlist_display_mode                 = "columns";
      browser_display_mode                  = "columns";
      search_engine_display_mode            = "columns";

      # --- columns ---
      song_columns_list_format = "(5)[cyan]{l} (30)[blue]{t|f} (20)[green]{a} (20)[magenta]{b}";
      song_list_format         = " $5%a $R$7 %t $8[%b]";
      song_status_format       = ''$b{{%a{ "%b"{ (%y)}} - }{%t}}|{%f}'';
      song_library_format      = "{%n - }{%t}|{%f}";

      # --- progress bar ---
      progressbar_look          = "── ";
      progressbar_color         = "black";
      progressbar_elapsed_color = "blue";

      # --- tokyo night colors ---
      colors_enabled       = "yes";
      color1               = "white";
      color2               = "blue";
      main_window_color    = "white";
      header_window_color  = "blue";
      volume_color         = "magenta";
      statusbar_color      = "blue";
      state_line_color     = "black";
      state_flags_color    = "blue:b";
      statusbar_time_color = "cyan:b";

      # --- statusbar ---
      header_visibility    = "no";

      # --- misc ---
      follow_now_playing_lyrics    = "yes";
      cyclic_scrolling             = "yes";
      mouse_support                = "yes";
      mouse_list_scroll_whole_page = "no";
      lines_scrolled               = 2;
      clock_display_seconds        = "yes";
      display_bitrate              = "yes";
      regular_expressions          = "extended";
      autocenter_mode              = "yes";
      centered_cursor              = "yes";
      ignore_leading_the           = "yes";
      external_editor              = "nvim";
      use_console_editor           = "yes";
    };

    bindings = [
      { key = "j";      command = "scroll_down"; }
      { key = "k";      command = "scroll_up"; }
      { key = "J";      command = "select_item"; }
      { key = "ctrl-f"; command = "page_down"; }
      { key = "ctrl-b"; command = "page_up"; }
      { key = "d";      command = "delete_playlist_items"; }
      { key = "+";      command = "volume_up"; }
      { key = "-";      command = "volume_down"; }
      { key = "g";      command = "move_home"; }
      { key = "G";      command = "move_end"; }
    ];
  };
}
