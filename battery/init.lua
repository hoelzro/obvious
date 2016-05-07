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
  local bats = { backend:state() }

  if #bats == 0 then
    widget:set_markup("no data")
    return
  end

  local markup = ''

  for i = 1, #bats do
    local bat = bats[i]
    local color

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
    end

    local status = status_text[bat.status] or 'unknown'

    local battery_status = lib.markup.fg.color(color, status) .. ' ' .. awful.util.escape(tostring(charge)) .. '%'

    if bat.time then
      local hours   = math.floor(bat.time / 60)
      local minutes = bat.time % 60

      battery_status = battery_status .. ' ' .. awful.util.escape(sformat('%02d:%02d', hours, minutes))
    end

    if i == 1 then
      markup = markup .. battery_status
    else
      markup = markup .. ' ' .. battery_status
    end
  end

  widget:set_markup(markup)
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
