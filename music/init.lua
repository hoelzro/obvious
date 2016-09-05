local backends = require 'obvious.music.backends'

local awful  = require 'awful'
local markup = require 'obvious.lib.markup'
local hooks  = require 'obvious.lib.hooks'
local wibox  = require 'wibox'

local widget = wibox.widget.textbox()
local backend
local marquee_timer

local format = '$title - $album - $artist'
local maxlength = 75
local unknown = '(unknown)'
local marquee = false

local function format_metadata(format, info)
  if type(format) == 'function' then
    return format(info)
  end

  assert(type(format) == 'string')

  return string.gsub(format, '%$(%w+)', function(key)
    return info[key] or unknown
  end)
end

local utf8length
local utf8positions

if utf8 then
  utf8length = utf8.len
else
  local sbyte = string.byte

  function utf8positions(s)
    local function iter(s, pos)
      if not pos then
        return 1
      end

      local byte = sbyte(s, pos)

      if byte >= 0xf0 then
        pos = pos + 4
      elseif byte >= 0xe0 then
        pos = pos + 3
      elseif byte >= 0xc0 then
        pos = pos + 2
      else
        pos = pos + 1
      end

      if pos > #s then
        return nil
      end

      return pos
    end

    if s == '' then
      return function() end, s, nil
    else
      return iter, s, nil
    end
  end

  function utf8length(s)
    local count = 0

    for _ in utf8positions(s) do
      count = count + 1
    end

    return count
  end
end

local function utf8sub(s, start, finish)
  local start_byte
  local end_byte = #s

  local charno = 1
  for pos in utf8positions(s) do
    if charno == start then
      start_byte = pos

      if not finish then
        break
      end
    end

    if finish and charno == finish + 1 then
      end_byte = pos - 1
      break
    end

    charno = charno + 1
  end

  return string.sub(s, start_byte, end_byte)
end

local function rotate_string(s)
  return function(_, v)
    return utf8sub(v, 2) .. utf8sub(v, 1, 1)
  end, s, s
end

local function scroll_marquee(s)
  for rotated in rotate_string(s) do
    local truncated = utf8sub(rotated, 1, maxlength - 3) .. '...'
    widget:set_markup(awful.util.escape(truncated))
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

  local formatted = format_metadata(format, info.info)

  if utf8length(formatted) > maxlength then
    if marquee then
      local marquee_coro = coroutine.create(scroll_marquee)
      coroutine.resume(marquee_coro, ' ' .. formatted)
      marquee_timer = function()
        coroutine.resume(marquee_coro)
      end
      hooks.timer.register(1, nil, marquee_timer, 'Marquee Timer')
      return
    else
      formatted = utf8sub(formatted, 1, maxlength - 3) .. '...'
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
