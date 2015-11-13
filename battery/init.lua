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
local backends = require 'obvious.battery.backends'

module("obvious.battery")

local widget = wibox.widget.textbox()
local status = {
  ["charged"] = "↯",
  ["full"] = "↯",
  ["high"] = "↯",
  ["discharging"] = "▼",
  ["not connected"] = "▼",
  ["charging"] = "▲",
  ["unknown"] = "⌁"
}

local backend

local function update()
  local battery_status = ""

  local bat = backend:state()
  -- XXX error handling
  if not bat then
    widget:set_markup("no data")
    return
  end
  local color = "#900000"
  if not bat.charge then
    widget:set_markup(lib.markup.fg.color("#009000", status.charged) .. " A/C")
    return
  elseif bat.charge > 35 and bat.charge < 60 then
    color = "#909000"
  elseif bat.charge >= 40 then
    color = "#009000"
  end

  local status = bat.status
  if not status[status] then
    status = "unknown"
  end
  status = status[status]

  battery_status = lib.markup.fg.color(color, status) .. " " .. awful.util.escape(tostring(bat.charge)) .. "%"

  if bat.time then
    battery_status = battery_status .. " " .. awful.util.escape(bat.time)
  end

  widget:set_markup(battery_status)
end

local function detail ()
  -- XXX error handling
  naughty.notify({
    text = backend:details(),
    screen = capi.mouse.screen
  })
  update()
end

widget:buttons(awful.util.table.join(
  awful.button({ }, 1, detail)
))
lib.hooks.timer.register(60, 300, update)

setmetatable(_M, { __call = function ()
  backend = backends.get()
  update()
  lib.hooks.timer.start(update)
  return widget
end })

-- vim:ft=lua:ts=2:sw=2:sts=2:tw=80:et
