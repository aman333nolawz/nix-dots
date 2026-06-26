-- idle_inhibit rules
hl.window_rule({
    match = { class = "^(.*celluloid.*)$|^(.*mpv.*)$|^(.*vlc.*)$" },
    idle_inhibit = "fullscreen",
})

hl.window_rule({
    match = { class = "^(.*[Ss]potify.*)$" },
    idle_inhibit = "fullscreen",
})

hl.window_rule({
    match = { class = "^(.*LibreWolf.*)$|^(.*floorp.*)$|^(.*brave-browser.*)$|^(.*firefox.*)$|^(.*chromium.*)$|^(.*zen.*)$|^(.*vivaldi.*)$" },
    idle_inhibit = "fullscreen",
})

-- Davinici resolve
hl.window_rule({
    name = "davinci-resolve-popup",

    match = {
        class = "resolve",
    },

    float = true,
    stay_focused = true,
    border_size = 0,
    no_shadow = true,
    rounding = 0,
})

-- Picture-in-Picture
hl.window_rule({
    name = "picture_in_picture",
    match = { title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" },
    float = true,
    keep_aspect_ratio = true,
    move = "(monitor_w*0.73) (monitor_h*0.72)",
    size = "(monitor_w*0.25) (monitor_h*0.25)",
    pin = true,
})

-- opacity rules
local opacity_rules = {
    { class = "^(firefox)$", opacity = "0.90 0.90 1" },
    { class = "^(zen)$", opacity = "0.90 0.90 1" },
    { class = "^(brave-browser)$", opacity = "0.90 0.90 1" },
    { class = "^(code-oss)$", opacity = "0.80 0.80 1" },
    { class = "^([Cc]ode)$", opacity = "0.80 0.80 1" },
    { class = "^(code-url-handler)$", opacity = "0.80 0.80 1" },
    { class = "^(code-insiders-url-handler)$", opacity = "0.80 0.80 1" },
    { class = "^(kitty)$", opacity = "0.80 0.80 1" },
    { class = "^(org.kde.dolphin)$", opacity = "0.80 0.80 1" },
    { class = "^(nemo)$", opacity = "0.80 0.80 1" },
    { class = "^(org.kde.ark)$", opacity = "0.80 0.80 1" },
    { class = "^(nwg-look)$", opacity = "0.80 0.80 1" },
    { class = "^(qt5ct)$", opacity = "0.80 0.80 1" },
    { class = "^(qt6ct)$", opacity = "0.80 0.80 1" },
    { class = "^(kvantummanager)$", opacity = "0.80 0.80 1" },
    { class = "^(org.pulseaudio.pavucontrol)$", opacity = "0.80 0.70 1" },
    { class = "^(blueman-manager)$", opacity = "0.80 0.70 1" },
    { class = "^(nm-applet)$", opacity = "0.80 0.70 1" },
    { class = "^(nm-connection-editor)$", opacity = "0.80 0.70 1" },
    { class = "^(org.kde.polkit-kde-authentication-agent-1)$", opacity = "0.80 0.70 1" },
    { class = "^(polkit-gnome-authentication-agent-1)$", opacity = "0.80 0.70 1" },
    { class = "^(org.freedesktop.impl.portal.desktop.gtk)$", opacity = "0.80 0.70 1" },
    { class = "^(org.freedesktop.impl.portal.desktop.hyprland)$", opacity = "0.80 0.70 1" },
    { class = "^([Ss]team)$", opacity = "0.70 0.70 1" },
    { class = "^(steamwebhelper)$", opacity = "0.70 0.70 1" },
    { class = "^([Ss]potify)$", opacity = "0.70 0.70 1" },
    { initial_title = "^(Spotify Free)$", opacity = "0.70 0.70 1" },
    { initial_title = "^(Spotify Premium)$", opacity = "0.70 0.70 1" },

    { class = "^(com.github.rafostar.Clapper)$", opacity = "0.90 0.90" },
    { class = "^(com.github.tchx84.Flatseal)$", opacity = "0.80 0.80" },
    { class = "^(hu.kramo.Cartridges)$", opacity = "0.80 0.80" },
    { class = "^(com.obsproject.Studio)$", opacity = "0.80 0.80" },
    { class = "^(gnome-boxes)$", opacity = "0.80 0.80" },
    { class = "^(vesktop)$", opacity = "0.80 0.80" },
    { class = "^(discord)$", opacity = "0.80 0.80" },
    { class = "^(WebCord)$", opacity = "0.80 0.80" },
    { class = "^(ArmCord)$", opacity = "0.80 0.80" },
    { class = "^(app.drey.Warp)$", opacity = "0.80 0.80" },
    { class = "^(net.davidotek.pupgui2)$", opacity = "0.80 0.80" },
    { class = "^(yad)$", opacity = "0.80 0.80" },
    { class = "^(Signal)$", opacity = "0.80 0.80" },
    { class = "^(io.github.alainm23.planify)$", opacity = "0.80 0.80" },
    { class = "^(io.gitlab.theevilskeleton.Upscaler)$", opacity = "0.80 0.80" },
    { class = "^(com.github.unrud.VideoDownloader)$", opacity = "0.80 0.80" },
    { class = "^(io.gitlab.adhami3310.Impression)$", opacity = "0.80 0.80" },
    { class = "^(io.missioncenter.MissionCenter)$", opacity = "0.80 0.80" },
    { class = "^(io.github.flattool.Warehouse)$", opacity = "0.80 0.80" },
}

for _, rule in ipairs(opacity_rules) do
    hl.window_rule({
        match = rule.class and { class = rule.class } or { initial_title = rule.initial_title },
        opacity = rule.opacity,
    })
end

-- float rules
local float_classes = {
    "^(Signal)$",
    "^(com.github.rafostar.Clapper)$",
    "^(app.drey.Warp)$",
    "^(net.davidotek.pupgui2)$",
    "^(yad)$",
    "^(eog)$",
    "^(io.github.alainm23.planify)$",
    "^(io.gitlab.theevilskeleton.Upscaler)$",
    "^(com.github.unrud.VideoDownloader)$",
    "^(io.gitlab.adhami3310.Impression)$",
    "^(io.missioncenter.MissionCenter)$",
    "^(resolve)$",
}

for _, cls in ipairs(float_classes) do
    hl.window_rule({
        match = { class = cls },
        float = true,
    })
end

-- workaround for jetbrains IDEs dropdowns/popups cause flickering
hl.window_rule({
    match = {
        class = "^(.*jetbrains.*)$",
        title = "^(win[0-9]+)$",
    },
    no_initial_focus = true,
})

-- layer rules
hl.layer_rule({
    match = { namespace = "rofi" },
    blur = true,
})
hl.layer_rule({
    match = { namespace = "rofi" },
    ignore_alpha = 0,
})

hl.layer_rule({
    match = { namespace = "notifications" },
    blur = true,
})
hl.layer_rule({
    match = { namespace = "notifications" },
    ignore_alpha = 0,
})

hl.layer_rule({
    match = { namespace = "swaync-notification-window" },
    blur = true,
})
hl.layer_rule({
    match = { namespace = "swaync-notification-window" },
    ignore_alpha = 0,
})

hl.layer_rule({
    match = { namespace = "swaync-control-center" },
    blur = true,
})
hl.layer_rule({
    match = { namespace = "swaync-control-center" },
    ignore_alpha = 0,
})

hl.layer_rule({
    match = { namespace = "logout_dialog" },
    blur = true,
})
