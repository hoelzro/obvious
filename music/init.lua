local backends = require 'obvious.music.backends'

local awful   = require 'awful'
local naughty = require 'naughty'
local markup  = require 'obvious.lib.markup'
local hooks   = require 'obvious.lib.hooks'
local unicode = require 'obvious.lib.unicode'
local wibox   = require 'wibox'

local widget = wibox.widget.textbox()
local backend
local marquee_timer

local format = '$title - $album - $artist'
local maxlength = 75
local unknown = '(unknown)'
local marquee = false

local icons = {
  playing = '⏵',
  paused  = '⏸',
  stopped = '⏹',
}

local function format_metadata(format, state, info)
  if type(format) == 'function' then
    return format(info)
  end

  info = setmetatable({ icon = icons[state] }, { __index = info })

  assert(type(format) == 'string')

  return string.gsub(format, '%$(%w+)', function(key)
    return awful.util.escape(info[key] or unknown)
  end)
end

local function rotate_string(s)
  return function(_, v)
    return unicode.sub(v, 2) .. unicode.sub(v, 1, 1)
  end, s, s
end

local function scroll_marquee(prefix, s, suffix)
  for rotated in rotate_string(s) do
    local truncated = unicode.sub(rotated, 1, maxlength - 3) .. '...'
    widget:set_markup(truncated)
    coroutine.yield()
  end
end

local function update(info)
  if marquee_timer then
    hooks.timer.unregister(marquee_timer)
    marquee_timer = nil
  end

  if not info then
    widget:set_markup(markup.fg.color('yellow', 'Music Off'))
    return
  end

  if info.state == 'stopped' then
    widget:set_markup 'Music Stopped'
    return
  end

  local formatted = format_metadata(format, info.state, info.info)

  if unicode.length(formatted) > maxlength then
    if marquee then
      local marquee_coro = coroutine.create(scroll_marquee)
      local ok, err = coroutine.resume(marquee_coro, ' ' .. formatted)
      if not ok then
        naughty.notify {
          title = 'Obvious',
          text = 'Error: ' .. tostring(err),
          preset = naughty.config.presets.critical,
        }
        return
      end

      marquee_timer = function()
        local ok, err = coroutine.resume(marquee_coro)
        if not ok then
          naughty.notify {
            title = 'Obvious',
            text = 'Error: ' .. tostring(err),
            preset = naughty.config.presets.critical,
          }
          hooks.timer.unregister(marquee_timer)
          marquee_timer = nil
        end
      end
      hooks.timer.register(1, nil, marquee_timer, 'Marquee Timer')
      return
    else
      formatted = unicode.sub(formatted, 1, maxlength - 3) .. '...'
    end
  end

  widget:set_markup(formatted)
end

local _M = {}

function _M.set_format(format_)
  format = format_
end

function _M.set_length(length_)
  maxlength = length_
end

function _M.set_unknown(unknown_)
  unknown = unknown_
end

function _M.set_marquee(marquee_)
  marquee = marquee_
end

function _M.set_backend(backend_name)
  local be = assert(backends[backend_name],
    string.format('Backend %q is not a valid backend', tostring(backend_name)))

  local err
  be, err = be:configure()
  assert(be, err or string.format('Unable to set up backend %q', tostring(backend_name)))
  backend = be

  backend:ontrackchange(update)
end

return setmetatable(_M, { __call = function() return widget end })
