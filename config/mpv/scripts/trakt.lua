-- Trakt scrobbler for mpv + uosc.
--
-- Install:
--   cp trakt.lua ~/.config/mpv/scripts/
--   cp trakt.py ~/.config/mpv/script-opts/
--   python3 ~/.config/mpv/script-opts/trakt.py --authorize
--
-- Optional config: ~/.config/mpv/script-opts/trakt.conf
--   key=alt+t
--   python=python3
--   script=~~/script-opts/trakt.py
--   auto=yes
--   notify=yes
--   min_duration=60
--   limit=10
--
-- Movies and SxxExx episodes are detected with guessit and scrobbled to
-- Trakt automatically. Press the key to change the match or track manually.

local mp = require('mp')
local utils = require('mp.utils')
local input = require('mp.input')

local SCRIPT_NAME = mp.get_script_name()
local MENU_SELECTOR = 'trakt_selector'

local function opt(name, default)
  local value = mp.get_opt(name)
  if value == nil or value == '' then
    return default
  end
  return value
end

local function opt_bool(name, default)
  local value = mp.get_opt(name)
  if value == nil or value == '' then
    return default
  end
  value = value:lower()
  return value == 'yes' or value == 'true' or value == '1'
end

local config = {
  key = opt('key', 'alt+t'),
  python = opt('python', 'python3'),
  script = opt('script', '~~/script-opts/trakt.py'),
  auto = opt_bool('auto', true),
  notify = opt_bool('notify', true),
  min_duration = tonumber(opt('min_duration', '60')) or 60,
  limit = tonumber(opt('limit', '10')) or 10,
}

local state = {
  media = nil,
  candidates = {},
  started = false,
  finished = false,
  last_progress = 0,
  error_shown = false,
}

local function expand_path(path)
  return mp.command_native({ 'expand-path', path })
end

local function notify(message, secs)
  secs = secs or 3
  mp.msg.info(message)
  mp.osd_message(message, secs)
end

local function menu_send(command, menu)
  mp.commandv('script-message-to', 'uosc', command, utils.format_json(menu))
end

local function run_python(args)
  local cmd = { config.python, expand_path(config.script) }
  for _, arg in ipairs(args) do
    table.insert(cmd, tostring(arg))
  end

  local result = utils.subprocess({ args = cmd, playback_only = false })
  local data = nil
  if result and result.stdout and result.stdout ~= '' then
    data = utils.parse_json(result.stdout)
  end
  return result or {}, data
end

local function open_url(url)
  if not url or url == '' then
    return
  end

  local platform = mp.get_property('platform')
  local cmd
  if platform == 'darwin' then
    cmd = { 'open', url }
  elseif platform == 'windows' then
    cmd = { 'cmd', '/c', 'start', '', url }
  else
    cmd = { 'xdg-open', url }
  end
  utils.subprocess({ args = cmd, playback_only = false })
end

local function current_progress()
  local position = mp.get_property_number('time-pos')
  local duration = mp.get_property_number('duration')
  if not position or not duration or duration <= 0 then
    return nil
  end
  position = math.max(0, position)
  return math.max(0, math.min(100, position / duration * 100))
end

local function media_hint(media)
  if media.kind == 'episode' then
    return string.format('TV  S%02dE%02d', media.season or 0, media.episode or 0)
  end
  if type(media.year) == 'number' then
    return 'Movie  ' .. media.year
  end
  return 'Movie'
end

local function reset_tracking()
  state.media = nil
  state.candidates = {}
  state.started = false
  state.finished = false
  state.last_progress = 0
  state.error_shown = false
end

local function send_scrobble(action, percent)
  if not state.media then
    return
  end

  percent = percent or state.last_progress
  if action == 'start' then
    percent = math.max(percent or 0, 0.1)
  elseif not percent or percent < 1 then
    return
  end

  local result, data = run_python({
    '--scrobble', action,
    '--kind', state.media.kind,
    '--trakt-id', tostring(state.media.trakt_id),
    '--progress', string.format('%.2f', percent),
  })

  if result.status ~= 0 or not data or not data.ok then
    if not state.error_shown then
      state.error_shown = true
      notify('Trakt: ' .. ((data and data.error) or 'scrobble failed'), 6)
    end
    return
  end

  if action == 'stop' and data.action == 'scrobble' and config.notify then
    notify('Trakt: Watched ' .. (state.media.display_name or state.media.title), 4)
  end
end

local function select_media(media)
  if state.media and state.media ~= media and state.started then
    send_scrobble('pause', current_progress() or state.last_progress)
  end

  state.media = media
  state.started = false
  state.finished = false
  state.error_shown = false

  local percent = current_progress()
  if percent then
    state.last_progress = percent
  end

  if config.notify then
    notify('Trakt: ' .. (media.display_name or media.title), 3)
  end

  if percent and percent > 0 and not mp.get_property_bool('pause') then
    state.started = true
    send_scrobble('start', percent)
  end
end

local function spinner_menu(title)
  return {
    type = MENU_SELECTOR,
    title = title,
    search_style = 'disabled',
    items = {
      {
        icon = 'spinner',
        title = 'Loading...',
        align = 'center',
        selectable = false,
        muted = true,
      },
    },
  }
end

local function error_menu(message)
  return {
    type = MENU_SELECTOR,
    title = 'Trakt',
    search_style = 'disabled',
    callback = { SCRIPT_NAME, 'menu-event' },
    items = {
      {
        title = message,
        align = 'center',
        selectable = false,
        muted = true,
        bold = true,
      },
      {
        title = 'Search by title...',
        icon = 'search',
        value = 'manual-search',
        separator = true,
      },
    },
  }
end

local function selector_menu(results)
  local items = {}
  for index, media in ipairs(results) do
    table.insert(items, {
      title = media.display_name or media.title,
      hint = media_hint(media),
      value = 'result:' .. index,
      actions = {
        {
          name = 'open_in_browser',
          icon = 'open_in_new',
          label = 'Open on Trakt',
        },
      },
    })
  end
  table.insert(items, {
    title = 'Search by title...',
    icon = 'search',
    value = 'manual-search',
    separator = true,
  })

  return {
    type = MENU_SELECTOR,
    title = 'Select a Trakt match',
    search_style = 'palette',
    callback = { SCRIPT_NAME, 'menu-event' },
    items = items,
  }
end

local function tracking_menu()
  local media = state.media
  return {
    type = MENU_SELECTOR,
    title = 'Trakt',
    search_style = 'disabled',
    callback = { SCRIPT_NAME, 'menu-event' },
    items = {
      {
        title = 'Tracking: ' .. (media.display_name or media.title),
        icon = 'check_circle',
        selectable = false,
        muted = true,
      },
      {
        title = 'Stop tracking',
        icon = 'stop',
        value = 'stop-tracking',
        separator = true,
      },
      {
        title = 'Change match...',
        icon = 'search',
        value = 'change-match',
      },
      {
        title = 'Search by title...',
        icon = 'search',
        value = 'manual-search',
      },
      {
        title = 'Open on Trakt',
        icon = 'open_in_new',
        value = 'open-browser',
      },
    },
  }
end

local function search_media(query)
  query = query or mp.get_property('filename/no-ext')
  if not query or query == '' then
    notify('Trakt: no file is playing', 4)
    return
  end

  menu_send('open-menu', spinner_menu('Searching Trakt...'))
  local result, data = run_python({
    '--search', query,
    '--title', mp.get_property('media-title') or '',
    '--limit', tostring(config.limit),
  })

  if result.status ~= 0 or not data or not data.ok then
    local message = (data and data.error) or result.stderr or 'Search failed'
    menu_send('update-menu', error_menu('Search failed: ' .. message))
    return
  end

  state.candidates = data.results or {}
  if #state.candidates == 0 then
    menu_send('update-menu', error_menu('No matches for: ' .. query))
    return
  end

  menu_send('update-menu', selector_menu(state.candidates))
end

local function prompt_search()
  mp.commandv('script-message-to', 'uosc', 'close-menu', MENU_SELECTOR)
  input.get({
    prompt = 'Search Trakt:',
    default_text = mp.get_property('media-title') or mp.get_property('filename/no-ext') or '',
    submit = function(text)
      if text and text ~= '' then
        search_media(text)
      end
    end,
  })
end

local function resolve_current(path, attempt)
  attempt = attempt or 1
  if state.media then
    return
  end

  path = path or mp.get_property('filename/no-ext')
  if not path then
    return
  end

  local duration = mp.get_property_number('duration')
  if not duration then
    if attempt < 4 then
      mp.add_timeout(1.5, function()
        if mp.get_property('filename/no-ext') == path and not state.media then
          resolve_current(path, attempt + 1)
        end
      end)
    end
    return
  end

  if duration < config.min_duration then
    return
  end

  local video = mp.get_property('video')
  if not video or video == 'no' then
    return
  end

  local result, data = run_python({
    '--match', path,
    '--title', mp.get_property('media-title') or '',
  })

  if result.status ~= 0 or not data or not data.ok then
    if not state.error_shown then
      state.error_shown = true
      local message = (data and data.error) or result.stderr or 'match failed'
      notify('Trakt: ' .. message, 6)
    end
    return
  end

  state.media = data.media
  state.started = false
  if config.notify then
    notify('Trakt: ' .. (state.media.display_name or state.media.title), 3)
  end

  -- Playback may already have started while the lookup was running.
  local percent = current_progress()
  if percent and percent > 0 and not mp.get_property_bool('pause') then
    state.started = true
    send_scrobble('start', percent)
  end
end

local function on_file_loaded()
  reset_tracking()
  if not config.auto then
    return
  end

  local path = mp.get_property('filename/no-ext')
  if not path then
    return
  end

  mp.add_timeout(1.5, function()
    if mp.get_property('filename/no-ext') == path and not state.media then
      resolve_current(path)
    end
  end)
end

local function on_time_pos(_, value)
  if not value then
    return
  end

  local percent = current_progress()
  if percent then
    state.last_progress = percent
  end

  if not state.media or state.started then
    return
  end
  if mp.get_property_bool('pause') then
    return
  end
  if not percent or percent <= 0 then
    return
  end

  state.started = true
  send_scrobble('start', percent)
end

local function on_pause(_, paused)
  if not state.media or not state.started or state.finished then
    return
  end

  local percent = current_progress() or state.last_progress
  if paused then
    send_scrobble('pause', percent)
  else
    send_scrobble('start', percent)
  end
end

local function on_eof(_, reached)
  if not state.media or not state.started then
    return
  end

  if not reached then
    if state.finished then
      state.finished = false
      state.started = false
    end
    return
  end

  if state.finished then
    return
  end

  -- keep-open=yes means end-file may not fire when playback reaches EOF.
  state.finished = true
  send_scrobble('stop', 100)
end

local function on_end_file()
  if state.media and state.started and not state.finished then
    local percent = current_progress() or state.last_progress
    send_scrobble('stop', percent)
  end
  reset_tracking()
end

local function handle_event(json)
  local event = utils.parse_json(json)
  if not event or event.type ~= 'activate' then
    return
  end

  local value = event.value
  if type(value) ~= 'string' then
    return
  end

  local index = value:match('^result:(%d+)$')
  if index then
    local media = state.candidates[tonumber(index)]
    if not media then
      return
    end
    if event.action == 'open_in_browser' or event.modifiers == 'shift' then
      open_url(media.url)
      mp.commandv('script-message-to', 'uosc', 'close-menu', MENU_SELECTOR)
    else
      select_media(media)
      mp.commandv('script-message-to', 'uosc', 'close-menu', MENU_SELECTOR)
    end
    return
  end

  if value == 'manual-search' then
    prompt_search()
    return
  end

  if value == 'change-match' then
    search_media(mp.get_property('filename/no-ext'))
    return
  end

  if value == 'stop-tracking' then
    if state.media and state.started and not state.finished then
      send_scrobble('stop', current_progress() or state.last_progress)
    end
    reset_tracking()
    mp.commandv('script-message-to', 'uosc', 'close-menu', MENU_SELECTOR)
    notify('Trakt: stopped tracking', 3)
    return
  end

  if value == 'open-browser' then
    if state.media then
      open_url(state.media.url)
    end
    return
  end
end

local function open_selector()
  if state.media then
    menu_send('open-menu', tracking_menu())
  else
    search_media(mp.get_property('filename/no-ext'))
  end
end

local function start_from_key()
  local open_menu = mp.get_property('user-data/uosc/menu/type')
  if open_menu and open_menu ~= '' and open_menu ~= 'undefined' and open_menu ~= 'null' then
    return
  end
  open_selector()
end

mp.register_event('file-loaded', on_file_loaded)
mp.register_event('end-file', on_end_file)
mp.observe_property('time-pos', 'number', on_time_pos)
mp.observe_property('pause', 'bool', on_pause)
mp.observe_property('eof-reached', 'bool', on_eof)
mp.add_key_binding(config.key, 'trakt-menu', start_from_key)
mp.register_script_message('menu-event', handle_event)
