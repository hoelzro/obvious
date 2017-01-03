local awful    = require 'awful'
local naughty  = require 'naughty'
local wibox    = require 'wibox'
local forecast = require 'obvious.weather.forecast'
local hooks    = require 'obvious.lib.hooks'
local cqueues  = require 'cqueues'

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

local request_in_flight = false

local function background_update()
  local response = forecast.get(api_key, latitude, longitude, metric and 'si' or 'us')

  local icon = icons[response.currently.icon] or ''
  local description = string.format('%.1f °%s', response.currently.temperature, metric and 'C' or 'us')
  widget:set_text(icon .. ' ' ..description)
  request_in_flight = false
end

local function update()
  if request_in_flight then
    return
  end
  request_in_flight = true

  local c = cqueues.new()
  c:wrap(background_update)
  local function check_up_on_request()
    local ok, err = c:step(0)

    if not ok then
      widget:set_text 'Unable to retrieve forecast @_@'
      naughty.notify {
        title = 'Forecast Error',
        text = err,
        preset = naughty.config.presets.critical,
      }
      request_in_flight = false
    end

    if not request_in_flight then
      hooks.timer.unregister(check_up_on_request)
    end
  end
  hooks.timer.register(0.1, 0.1, check_up_on_request)
end

local function is_setup()
  return api_key and latitude and longitude
end

local function init_timer()
  if not is_setup() or timer_running then
    return
  end

  timer_running = true
  widget:set_text 'Retrieving forecast...'
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

widget:buttons(awful.util.table.join(
  awful.button({ }, 1, update)
))

return setmetatable(_M, { __call = function()
  if is_setup() then
    init_timer()
  else
    widget:set_text 'Setup Required'
  end

  return widget
end })
