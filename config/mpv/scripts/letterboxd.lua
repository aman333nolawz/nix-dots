-- Letterboxd movie logger for mpv + uosc.
--
-- Install:
--   cp letterboxd.lua ~/.config/mpv/scripts/
--   cp rate_movie.py ~/.config/mpv/script-opts/
--   And store cookies in ~/.local/share/letterboxd/cookies.txt
--   cookies should be like: (You can get them from your browser dev tools)
--   com.xk72.webparts.csrf="<some hex string>";
--   letterboxd.user="<some hex string>";
--
-- Optional config: ~/.config/mpv/script-opts/letterboxd.conf
--   key=alt+l
--   python=python3
--   script=~~/script-opts/rate_movie.py
--   limit=15
--
-- Default key: alt+l (press it while a movie is playing).

local mp = require('mp')
local utils = require('mp.utils')
local input = require('mp.input')

local SCRIPT_NAME = mp.get_script_name()
local MENU_SELECTOR = 'letterboxd_selector'
local MENU_COMPOSE = 'letterboxd_compose'

local function opt(name, default)
  local value = mp.get_opt(name)
  if value == nil or value == '' then
    return default
  end
  return value
end

local config = {
  key = opt('key', 'alt+l'),
  python = opt('python', 'python3'),
  script = opt('script', '~~/script-opts/rate_movie.py'),
  limit = tonumber(opt('limit', '15')) or 15,
}

local state = {
  films = {},
  film = nil,
  rating = nil,
  rewatch = false,
  liked = false,
  busy = false,
}

local COOKIE_PATH = (os.getenv('HOME') or '')
  .. '/.local/share/letterboxd/cookies.txt'

local function expand_path(path)
  return mp.command_native({ 'expand-path', path })
end

local function notify(message, secs)
  secs = secs or 3
  mp.msg.info(message)
  mp.osd_message(message, secs)
end

local function require_cookies()
  if utils.file_info(COOKIE_PATH) then
    return true
  end
  notify(
    'Letterboxd: cookies.txt not found. Export your Letterboxd cookies to '
      .. COOKIE_PATH,
    8
  )
  return false
end

local function menu_send(command, menu)
  mp.commandv('script-message-to', 'uosc', command, utils.format_json(menu))
end

local function spinner_menu(menu_type, title)
  return {
    type = menu_type,
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

local function film_hint(film)
  local parts = {}
  if type(film.year) == 'number' then
    table.insert(parts, tostring(film.year))
  end
  if type(film.rating) == 'number' then
    table.insert(parts, string.format('★ %.2f', film.rating))
  end
  return table.concat(parts, '   ')
end

local function selector_menu(films)
  local items = {}
  for _, film in ipairs(films) do
    table.insert(items, {
      title = film.display_name or film.title,
      hint = film_hint(film),
      value = 'film:' .. film.lid,
      actions = {
        {
          name = 'open_in_browser',
          icon = 'open_in_new',
          label = 'Open on Letterboxd',
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
    title = 'Select a film',
    search_style = 'palette',
    callback = { SCRIPT_NAME, 'menu-event' },
    items = items,
  }
end

local function selector_error(message)
  return {
    type = MENU_SELECTOR,
    title = 'Letterboxd',
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

local function find_film(lid)
  for _, film in ipairs(state.films) do
    if film.lid == lid then
      return film
    end
  end
  return nil
end

local function start_search(query)
  query = query or mp.get_property('path')
  if not query or query == '' then
    notify('No file is playing', 4)
    return
  end

  menu_send('open-menu', spinner_menu(MENU_SELECTOR, 'Searching Letterboxd...'))
  local result, data = run_python({
    '--search', query,
    '--json',
    '--limit', tostring(config.limit),
  })

  if result.status ~= 0 or not data or not data.ok then
    local message = (data and data.error) or result.stderr or 'Search failed'
    menu_send('update-menu', selector_error('Search failed: ' .. message))
    return
  end

  local films = data.results or {}
  if #films == 0 then
    menu_send('update-menu', selector_error('No films found for: ' .. query))
    return
  end

  state.films = films
  menu_send('update-menu', selector_menu(films))
end

local function prompt_search()
  mp.commandv('script-message-to', 'uosc', 'close-menu', MENU_SELECTOR)
  mp.commandv('script-message-to', 'uosc', 'close-menu', MENU_COMPOSE)

  input.get({
    prompt = 'Search Letterboxd:',
    default_text = mp.get_property('path') or '',
    submit = function(text)
      if text and text ~= '' then
        start_search(text)
      end
    end,
  })
end

local function compose_menu()
  local film = state.film
  local rating_label = state.rating and string.format('%.1f ★', state.rating) or 'none'

  local rating_items = {
    {
      title = 'No rating',
      icon = state.rating == nil and 'radio_button_checked' or 'radio_button_unchecked',
      value = 'set-rating:none',
      keep_open = true,
    },
  }
  for step = 1, 10 do
    local value = step * 0.5
    table.insert(rating_items, {
      title = string.format('%.1f ★', value),
      icon = state.rating == value and 'radio_button_checked' or 'radio_button_unchecked',
      value = 'set-rating:' .. tostring(value),
      keep_open = true,
    })
  end

  local items = {
    {
      title = 'Rating',
      icon = 'star',
      hint = rating_label,
      items = rating_items,
    },
    {
      title = 'Rewatch',
      icon = state.rewatch and 'check_box' or 'check_box_outline_blank',
      hint = state.rewatch and 'yes' or 'no',
      value = 'toggle-rewatch',
      keep_open = true,
    },
    {
      title = 'Like',
      icon = state.liked and 'favorite' or 'favorite_border',
      hint = state.liked and 'yes' or 'no',
      value = 'toggle-like',
      keep_open = true,
    },
    {
      title = 'Date',
      icon = 'today',
      hint = os.date('%Y-%m-%d'),
      selectable = false,
      muted = true,
    },
    {
      title = 'Log film',
      icon = 'check_circle',
      hint = film and film.display_name or nil,
      value = 'submit',
      keep_open = false,
    },
    {
      title = 'Change film',
      icon = 'search',
      value = 'change-film',
      separator = true,
    },
    {
      title = 'Open on Letterboxd',
      icon = 'open_in_new',
      value = 'open-browser',
    },
  }

  return {
    type = MENU_COMPOSE,
    title = film and ('Log: ' .. film.display_name) or 'Log film',
    keep_open = true,
    search_style = 'disabled',
    callback = { SCRIPT_NAME, 'menu-event' },
    items = items,
  }
end

local function refresh_compose(reset)
  menu_send(reset and 'open-menu' or 'update-menu', compose_menu())
end

local function open_compose(film)
  state.film = film
  state.rating = nil
  state.rewatch = false
  state.liked = false
  state.busy = false

  menu_send('open-menu', spinner_menu(MENU_COMPOSE, 'Checking viewing history...'))
  local result, data = run_python({
    '--log', film.url,
    '--json',
    '--dry-run',
  })

  if result.status == 0 and data and data.ok then
    state.rewatch = data.rewatch and true or false
    state.liked = data.liked and true or false
  end

  refresh_compose(false)
end

local function submit_log()
  if state.busy or not state.film then
    return
  end
  state.busy = true

  local menu = compose_menu()
  menu.items = {
    {
      icon = 'spinner',
      title = 'Logging...',
      align = 'center',
      selectable = false,
      muted = true,
    },
  }
  menu_send('update-menu', menu)

  local args = { '--log', state.film.url, '--json' }
  if state.rating then
    table.insert(args, '--rating')
    table.insert(args, tostring(state.rating))
  end
  table.insert(args, state.rewatch and '--rewatch' or '--no-rewatch')
  table.insert(args, state.liked and '--like' or '--no-like')

  local result, data = run_python(args)
  state.busy = false

  if result.status == 0 and data and data.ok then
    local label = (data.film and data.film.display_name) or state.film.display_name
    notify('Logged: ' .. label, 4)
    mp.commandv('script-message-to', 'uosc', 'close-menu', MENU_COMPOSE)
  else
    local message = (data and data.error) or result.stderr or 'Logging failed'
    notify('Letterboxd: ' .. message, 5)
    refresh_compose(false)
  end
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

  if value:sub(1, 5) == 'film:' then
    local film = find_film(value:sub(6))
    if not film then
      return
    end
    if event.action == 'open_in_browser' or event.modifiers == 'shift' then
      open_url(film.url)
      mp.commandv('script-message-to', 'uosc', 'close-menu', MENU_SELECTOR)
    else
      open_compose(film)
    end
    return
  end

  if value == 'manual-search' then
    prompt_search()
    return
  end

  if value == 'set-rating:none' then
    state.rating = nil
    refresh_compose(true)
    return
  end

  local rating_value = value:match('^set%-rating:([%d%.]+)$')
  if rating_value then
    state.rating = tonumber(rating_value)
    refresh_compose(true)
    return
  end

  if value == 'toggle-rewatch' then
    state.rewatch = not state.rewatch
    refresh_compose(false)
    return
  end

  if value == 'toggle-like' then
    state.liked = not state.liked
    refresh_compose(false)
    return
  end

  if value == 'change-film' then
    if #state.films > 0 then
      menu_send('open-menu', selector_menu(state.films))
    else
      start_search(mp.get_property('path'))
    end
    return
  end

  if value == 'open-browser' then
    if state.film then
      open_url(state.film.url)
    end
    return
  end

  if value == 'submit' then
    submit_log()
    return
  end
end

local function start_from_key()
  local open_menu = mp.get_property('user-data/uosc/menu/type')
  if open_menu and open_menu ~= '' and open_menu ~= 'undefined' and open_menu ~= 'null' then
    return
  end
  if not require_cookies() then
    return
  end
  start_search(mp.get_property('path'))
end

mp.add_key_binding(config.key, 'letterboxd-log', start_from_key)

mp.register_script_message('menu-event', handle_event)
