local mod = "SUPER"
local browser = "zen"

-- settings.bind
hl.bind(mod .. " + R", (hl.dsp.exec_cmd("rofi -show drun")))
hl.bind(mod .. " + V", hl.dsp.exec_cmd("noctalia msg panel-toggle clipboard"))
hl.bind(mod .. " + PERIOD", hl.dsp.exec_cmd("noctalia msg panel-toggle launcher /emo"))
hl.bind(mod .. " + N", hl.dsp.exec_cmd("noctalia msg panel-toggle control-center notifications"))
hl.bind(mod .. " + SHIFT + W", hl.dsp.exec_cmd("noctalia msg panel-toggle wallpaper"))

hl.bind(mod .. " + RETURN", (hl.dsp.exec_cmd("$TERMINAL")))
hl.bind(mod .. " + E", hl.dsp.exec_cmd("$EXPLORER"))
hl.bind(mod .. " + B", hl.dsp.exec_cmd(browser))

hl.bind(mod .. " + X", hl.dsp.exec_cmd("~/.config/rofi/powermenu/type-2/powermenu.sh"))
hl.bind(mod .. " + L", hl.dsp.exec_cmd("hyprlock"))

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
hl.bind(mod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(mod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(mod .. " + down", hl.dsp.focus({ direction = "down" }))

-- Switch workspaces with mod + [0-9]
-- Move active window to a workspace with mod + SHIFT + [0-9]
for i = 1, 10 do
  local key = i % 10 -- 10 maps to key 0
  hl.bind(mod .. " + " .. key, hl.dsp.focus({ workspace = i }))
  hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Switch window
hl.bind("ALT + TAB", hl.dsp.exec_cmd("noctalia msg window-switcher"))

-- Move windows left, right, up and down in split
hl.bind(mod .. " + SHIFT + left", hl.dsp.window.move({ direction = "left" }))
hl.bind(mod .. " + SHIFT + right", hl.dsp.window.move({ direction = "right" }))
hl.bind(mod .. " + SHIFT + up", hl.dsp.window.move({ direction = "up" }))
hl.bind(mod .. " + SHIFT + down", hl.dsp.window.move({ direction = "down" }))

-- scratchpad
hl.bind(mod .. " + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Move/resize windows with mod + LMB/RMB and dragging
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Laptop multimedia keys for volume and LCD brightness
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("noctalia msg volume-up"),
  { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("noctalia msg volume-down"),
  { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("noctalia msg volume-mute"),
  { locked = true, repeating = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("noctalia msg mic-mute"),
  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("noctalia msg brightness-up"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("noctalia msg brightness-down"), { locked = true, repeating = true })

-- Requires playerctl
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

-- Screen capture stuff
hl.bind(mod .. " + P", hl.dsp.exec_cmd('noctalia msg screenshot-fullscreen --annotate'))
hl.bind(mod .. " + SHIFT + P", hl.dsp.exec_cmd('noctalia msg screenshot-region --annotate'))
hl.bind("Print", hl.dsp.exec_cmd('noctalia msg screenshot-fullscreen --annotate'))
hl.bind("SUPER + Print", hl.dsp.exec_cmd('noctalia msg screenshot-region --annotate'))
hl.bind(mod .. " + CTRL + P", hl.dsp.exec_cmd("hyprpicker -an"))
