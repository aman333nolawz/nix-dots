local mod = "SUPER"
local browser = "zen"

-- settings.bind
hl.bind("SUPER + SUPER_L", (hl.dsp.exec_cmd("rofi -show drun")))
hl.bind(mod .. " + V", hl.dsp.exec_cmd("noctalia-shell ipc call launcher clipboard"))
hl.bind(mod .. " + PERIOD", hl.dsp.exec_cmd("noctalia-shell ipc call launcher emoji"))
hl.bind(mod .. " + N", hl.dsp.exec_cmd("noctalia-shell ipc call notifications toggleHistory"))
hl.bind(mod .. " + SHIFT + W", hl.dsp.exec_cmd("noctalia-shell ipc call wallpaper toggle"))

hl.bind(mod .. " + RETURN", (hl.dsp.exec_cmd("$TERMINAL")))
hl.bind(mod .. " + E", hl.dsp.exec_cmd("$EXPLORER"))
hl.bind(mod .. " + B", hl.dsp.exec_cmd(browser))

hl.bind(mod .. " + X", hl.dsp.exec_cmd("~/.config/rofi/powermenu/type-2/powermenu.sh"))
hl.bind(mod .. " + L", hl.dsp.exec_cmd("qylock-lock"))

hl.bind(mod .. " + A", hl.dsp.exec_cmd("curd"))
hl.bind(mod .. " + ALT + B", hl.dsp.exec_cmd("~/.local/bin/blueconn"))
hl.bind(mod .. " + SHIFT + N", hl.dsp.exec_cmd("~/.local/bin/epaper"))
hl.bind(mod .. " + W", hl.dsp.exec_cmd("~/.local/bin/watch_streams"))
hl.bind(mod .. " + D", hl.dsp.exec_cmd("~/.local/bin/dictionary"))

hl.bind("SHIFT + F11", hl.dsp.window.fullscreen())
hl.bind((mod .. " + F"), hl.dsp.window.fullscreen())

hl.bind(mod .. " + SPACE", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mod .. " + J", hl.dsp.layout("togglesplit"))
hl.bind(mod .. " + Q", hl.dsp.window.close())

-- Move focus with mod + arrow keys
hl.bind(mod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- Switch workspaces with mod + [0-9]
-- Move active window to a workspace with mod + SHIFT + [0-9]
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mod .. " + " .. key,             hl.dsp.focus({ workspace = i}))
    hl.bind(mod .. " + SHIFT + " .. key,     hl.dsp.window.move({ workspace = i }))
end

-- scratchpad
hl.bind(mod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Move/resize windows with mod + LMB/RMB and dragging
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Laptop multimedia keys for volume and LCD brightness
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown",hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true })

-- Requires playerctl
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

-- Screen capture stuff
hl.bind(mod .. " + P", hl.dsp.exec_cmd('grim - | satty -f - --copy-command wl-copy -o "~/Pictures/Screenshots/%Y%m%d_%H%M%S.png"'))
hl.bind(mod .. " + SHIFT + P", hl.dsp.exec_cmd('grim -g "$(slurp -d)" - | satty -f - --copy-command wl-copy -o "~/Pictures/Screenshots/%Y%m%d_%H%M%S.png"'))
hl.bind("Print", hl.dsp.exec_cmd('grim - | satty -f - --copy-command wl-copy -o "~/Pictures/Screenshots/%Y%m%d_%H%M%S.png"'))
hl.bind("SUPER + Print", hl.dsp.exec_cmd('grim -g "$(slurp -d)" - | satty -f - --copy-command wl-copy -o "~/Pictures/Screenshots/%Y%m%d_%H%M%S.png'))
hl.bind(mod .. " + CTRL + P", hl.dsp.exec_cmd("hyprpicker -an"))
