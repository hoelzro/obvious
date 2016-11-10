local naughty  = require 'naughty'
local wibox    = require 'wibox'
local forecast = require 'obvious.weather.forecast'
local hooks    = require 'obvious.lib.hooks'

local widget = wibox.widget.textbox()
local timer_running

local api_key
local latitude
local longitude
local metric = true

local icons = {
  ['clear-day']           = '☼',
  ['clear-night']         = '🌙',
  ['partly-cloudy-day']   = '⛅',
  ['partly-cloudy-night'] = '⛅',
  cloudy                  = '☁',
  rain                    = '🌧',
  sleet                   = '',
  snow                    = '❄',
  wind                    = '',
  fog                     = '🌁',
}

local function update()
  local response, err = pcall(forecast.get, api_key, latitude, longitude, metric and 'si' or 'us')

  if not response then
    widget:set_text('Unable to retrieve forecast: ' .. err)
    return
  end
  response = err

  local icon = icons[response.currently.icon] or ''
  local description = string.format('%.1f °%s', response.currently.temperature, metric and 'C' or 'us')
  widget:set_text(icon .. ' ' ..description)
end

local function is_setup()
  return api_key and latitude and longitude
end

local function init_timer()
  if not is_setup() or timer_running then
    return
  end

  timer_running = true
  update()
  hooks.timer.register(15 * 60, 60 * 60, update, 'weather widget refresh rate')
end

local _M = {}

function _M.set_api_key(key)
  api_key = key
  init_timer()
end

function _M.set_latitude(lat)
  latitude = lat
  init_timer()
end

function _M.set_longitude(long)
  longitude = long
  init_timer()
end

function _M.set_metric(is_metric)
  metric = is_metric
end

return setmetatable(_M, { __call = function()
  if is_setup() then
    init_timer()
  else
    widget:set_text 'Setup Required'
  end

  return widget
end })
