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

module("obvious.battery")

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

local function update()
  local battery_status = ""

  local bat = backend:state()
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
  if not status_text[status] then
    status = "unknown"
  end
  status = status_text[status]

  battery_status = lib.markup.fg.color(color, status) .. " " .. awful.util.escape(tostring(bat.charge)) .. "%"

  if bat.time then
    local hours   = math.floor(bat.time / 60)
    local minutes = bat.time % 60

    battery_status = battery_status .. " " .. awful.util.escape(sformat('%02d:%02d', hours, minutes))
  end

  widget:set_markup(battery_status)
end

local function detail ()
  local details = backend:details()

  if not details then
    details = 'no details available'
  end
  naughty.notify({
    text = details,
    screen = capi.mouse.screen,
  })
  update()
end

widget:buttons(awful.util.table.join(
  awful.button({ }, 1, detail)
))
lib.hooks.timer.register(60, 300, update)

setmetatable(_M, { __call = function ()
  backend = backends.get(_M.preferred_backend)
  update()
  lib.hooks.timer.start(update)
  return widget
end })

-- vim:ft=lua:ts=2:sw=2:sts=2:tw=80:et
