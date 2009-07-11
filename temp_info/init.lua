-----------------------------------
-- Author: Eligio Becerra        --
-- Copyright 2009 Eligio Becerra --
-----------------------------------

local awful = require("awful")

local capi = {
   widget = widget,
   screen = screen
}

module("obvious.temp_zone")
      
widget = capi.widget({
   type = "textbox",
    name = "temp_zone",
    align = "right"
})

colors{
   normal = "#009000",
   warm = "#909000",
   hot = "#900000"
}

local function update(_zone)
   local temp = awful.util.pread('awk \'{print $2 "°C"}\' /proc/acpi/thermal_zone/'.._zone..'/temperature')
   local color
   if temp < 50 then
      color = colors[normal]
   else
      if temp >= 50 and temp < 60 then
	 color = colors[warm]
      else
	 color = colors[hot]
  widget.text = " ".._zone.." :: <span color=\""..color.."\">"..temp.." </span> "
end

awful.hooks.timer.register(5, update)

setmetatable(_M, { __call = function ("TZS0") return widget end })
