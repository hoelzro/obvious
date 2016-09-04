local backends = require 'obvious.music.backends'

local awful  = require 'awful'
local markup = require 'obvious.lib.markup'
local wibox  = require 'wibox'

local widget = wibox.widget.textbox()
local backend

local format = '$title - $album - $artist'
local maxlength = 75
local unknown = '(unknown)'

local function format_metadata(format, info)
  if type(format) == 'function' then
    return format(info)
  end

  assert(type(format) == 'string')

  return string.gsub(format, '%$(%w+)', function(key)
    return info[key] or unknown
  end)
end

local function update(info)
  if not info then
    widget:set_markup(markup.fg.color('yellow', 'Music Off'))
    return
  end

  if info.state == 'stopped' then
    widget:set_markup 'Music Stopped'
    return
  end

  local formatted = format_metadata(format, info.info)

  -- XXX UTF-8/graphemes
  if string.len(formatted) > maxlength then
    formatted = string.sub(formatted, 1, maxlength - 3) .. '...'
  end

  formatted = awful.util.escape(formatted)

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
