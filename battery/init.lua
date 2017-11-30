--------------------------------------------
-- Author: Gregor Best                    --
-- Copyright 2009, 2010, 2011 Gregor Best --
--------------------------------------------

local tonumber = tonumber
local tostring = tostring
local setmetatable = setmetatable
local type = type
local io = {
  popen = io.popen
}
local capi = {
  mouse = mouse
}
local table = {
  remove = table.remove
}
local math = {
  floor = math.floor
}

local naughty = require("naughty")
local awful = require("awful")
local wibox = require("wibox")
local lib = {
  hooks = require("obvious.lib.hooks"),
  markup = require("obvious.lib.markup")
}
local sformat = string.format
local backends = require 'obvious.battery.backends'

local battery = {}

local widget = wibox.widget.textbox()
local status_text = {
  ["charged"] = "↯",
  ["full"] = "↯",
  ["high"] = "↯",
  ["discharging"] = "▼",
  ["not connected"] = "▼",
  ["charging"] = "▲",
  ["unknown"] = "⌁"
}

local backend

local inverted = false
local cycle_count = 0
local previous_state

local function update(force)
  if not backend then
    return
  end

  if force then
    cycle_count = 0
  end
  if cycle_count == 0 then
    previous_state = { backend:state() }
  end
  cycle_count = (cycle_count + 1) % 60
  local bats = previous_state

  if #bats == 0 then
    widget:set_markup("no data")
    return
  end

  local markup = ''

  for i = 1, #bats do
    local bat = bats[i]
    local color

    local blinking = false

    local charge = bat.charge

    if charge == nil then
      color = '#900000'
      charge = 'Unknown charge'
    elseif charge >= 60 then
      color = '#009000'
    elseif charge > 35 then
      color = '#909000'
    else
      color = '#900000'
      blinking = bat.charge <= 20 and (bat.status == 'discharging' or bat.status == 'not connected')
    end

    local status = status_text[bat.status] or 'unknown'

    local battery_status

    if blinking and inverted then
      battery_status = status .. ' ' .. awful.util.escape(tostring(bat.charge)) .. '%'
    else
      battery_status = lib.markup.fg.color(color, status) .. ' ' .. awful.util.escape(tostring(bat.charge)) .. '%'
    end

    if bat.time then
      local hours   = math.floor(bat.time / 60)
      local minutes = bat.time % 60

      battery_status = battery_status .. ' ' .. awful.util.escape(sformat('%02d:%02d', hours, minutes))
    end

    if blinking and inverted then
      battery_status = lib.markup.bg.color(color, battery_status)
    end
    inverted = not inverted

    if i == 1 then
      markup = markup .. battery_status
    else
      markup = markup .. ' ' .. battery_status
    end
  end

  widget:set_markup(markup)
end

local function detail()
  local details = backend:details()

  if not details then
    details = 'no details available'
  end
  naughty.notify({
    text = details,
    screen = capi.mouse.screen,
  })
  update(true)
end

function battery.get_data()
  if not backend then
    backend = backends.get(battery.preferred_backend)
  end

  local bats = { backend:state() }
  if bats then
    return bats[1]
  end
end

widget:buttons(awful.util.table.join(
  awful.button({ }, 1, detail)
))
-- XXX FIXME
lib.hooks.timer.register(1, 300, update)

setmetatable(battery, { __call = function ()
  if not backend then
     backend = backends.get(battery.preferred_backend)
  end
  update()
  lib.hooks.timer.start(update)
  return widget
end })
require('obvious.widget_registry').battery = battery
return battery

-- vim:ft=lua:ts=2:sw=2:sts=2:tw=80:et
