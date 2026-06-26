{ pkgs, inputs, ... }:
{
    imports = [
      inputs.noctalia.homeModules.default
    ];

    # configure options
    programs.noctalia-shell = {
      enable = true;
      settings = {
        # configure noctalia here
        dock.enabled = false;
        ui = {
          fontDefault = "Roboto";
          fontFixed = "CaskaydiaCove Nerd Font Mono";
          settingsPanelMode = "window";
        };
        bar = {
          density = "default";
          position = "top";
          showCapsule = false;
          widgets = {
            left = [
              {
                id = "ControlCenter";
                useDistroLogo = true;
              }
              {
                characterCount = 2;
                colorizeIcons = false;
                emptyColor = "secondary";
                enableScrollWheel = true;
                focusedColor = "primary";
                followFocusedScreen = false;
                fontWeight = "bold";
                groupedBorderOpacity = 1;
                hideUnoccupied = false;
                iconScale = 0.8;
                id = "Workspace";
                labelMode = "index";
                occupiedColor = "tertiary";
                pillSize = 0.6;
                showApplications = false;
                showApplicationsHover = false;
                showBadge = true;
                showLabelsOnlyWhenOccupied = true;
                unfocusedIconsOpacity = 1;
              }
              {
                id = "plugin:github-feed";
              }
            ];
            center = [
              {
                iconColor = "none";
                id = "KeepAwake";
                textColor = "none";
              }
              {
                clockColor = "none";
                customFont = "";
                formatHorizontal = "HH:mm ddd, MMM dd";
                formatVertical = "HH mm - dd MM";
                id = "Clock";
                tooltipFormat = "HH:mm ddd, MMM dd";
                useCustomFont = false;
              }
            ];
            right = [
              {
                drawerEnabled = false;
                id = "Tray";
              }
              {
                displayMode = "onhover";
                iconColor = "primary";
                textColor = "none";
                id = "VPN";
              }
              {
                displayMode = "onhover";
                iconColor = "primary";
                textColor = "none";
                id = "Network";
              }
              {
                displayMode = "onhover";
                iconColor = "primary";
                id = "Bluetooth";
                textColor = "none";
              }
              {
                id = "Spacer";
                width = 2;
              }
              {
                displayMode = "onhover";
                iconColor = "tertiary";
                id = "Volume";
                middleClickCommand = "pwvucontrol || pavucontrol";
                textColor = "none";
              }
              {
                applyToAllMonitors = false;
                displayMode = "onhover";
                iconColor = "tertiary";
                id = "Brightness";
                textColor = "tertiary";
              }
              {
                id = "Spacer";
                width = 2;
              }
              {
                id = "plugin:battery-monitor-plus";
                displayMode = "graphic";
              }
              {
                hideWhenZero = false;
                hideWhenZeroUnread = false;
                iconColor = "tertiary";
                id = "NotificationHistory";
                showUnreadBadge = true;
                unreadBadgeColor = "primary";
              }
            ];
          };
        };
        colorSchemes = {
          useWallpaperColors = true;
          generationMethod = "tonal-spot";
        };
        general = {
          avatarImage = "/home/nolawz/Pictures/Wallpapers/wallhaven-9ory8k_1920x1200.png";
          radiusRatio = 0.2;
        };
        appLauncher = {
          enableClipboardHistory = true;
          overviewLayer = true;
        };
        osd = {
          location = "bottom";
          backgroundOpacity = 0.2;
        };
        notifications = {
          density = "compact";
          backgroundOpacity = 0.70;
        };
        wallpaper = {
          transitionType = [
            "disc"
            "stripes"
            "wipe"
            "pixelate"
            "honeycomb"
          ];
        };
        location = {
          name = "Malappuram";
        };
      };
    };
}
