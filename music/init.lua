local backends = require 'obvious.music.backends'

local awful       = require 'awful'
local naughty     = require 'naughty'
local markup      = require 'obvious.lib.markup'
local hooks       = require 'obvious.lib.hooks'
local unicode     = require 'obvious.lib.unicode'
local markup_rope = require 'obvious.lib.markup_rope'
local wibox       = require 'wibox'

local min = math.min

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

local function rotate_markup_string(s, maxlength)
  return function(rope, rotation_amount)
    local first_chunk_length = min(rope:len() - rotation_amount, maxlength)

    local rotated = rope:sub(rotation_amount + 1, rotation_amount + first_chunk_length + 1)

    if first_chunk_length < maxlength then
      rotated = rotated .. rope:sub(1, min(maxlength - first_chunk_length, rotation_amount))
    end

    return (rotation_amount % rope:len()) + 1, rotated
  end, markup_rope(s), 1
end

local function scroll_marquee(prefix, s, suffix)
  local maxlength = maxlength - markup_rope(prefix):len() - markup_rope(suffix):len()
  for _, rotated in rotate_markup_string(s, maxlength - 3) do
    widget:set_markup(prefix .. rotated .. '...' .. suffix)
    local current_width = widget:get_preferred_size()
    if current_width > (widget.forced_width or 0) then
      widget.forced_width = current_width
    end

    coroutine.yield()
  end
end

local function parse_marquee(format)
  local start, finish, inner = string.find(format, '<marquee>(.*)</marquee>')

  if not start then
    return '', format, ''
  end

  return string.sub(format, 1, start - 1), inner, string.sub(format, finish + 1)
end

local function update(info)
  widget.forced_width = nil
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
      local prefix, marquee_text, suffix = parse_marquee(formatted)
      local ok, err = coroutine.resume(marquee_coro, prefix, ' ' .. marquee_text, suffix)
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
      formatted = markup_rope(formatted):sub(1, maxlength - 3) .. '...'
    end
  end

  formatted = table.concat { parse_marquee(formatted) }

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

local music = setmetatable(_M, { __call = function() return widget end })
require('obvious.widget_registry').music = music
return music
