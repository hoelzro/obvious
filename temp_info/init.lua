-----------------------------------
-- Author: Eligio Becerra        --
-- Copyright 2009 Eligio Becerra --
-----------------------------------

local awful = require("awful")
local setmetatable = setmetatable
local tonumber = tonumber
local tostring = tostring
local type = type
local ipairs = ipairs
local print = print
local capi = {
   widget = widget,
   screen = screen
}

module("obvious.temp_info")

widget = capi.widget({
   type = "textbox",
   name = "temp_zone",
   align = "right"
})

colors = {
   ["normal"] = "#009000",
   ["warm"] = "#909000",
   ["hot"] = "#900000"
}

function update()
   local temp = awful.util.pread('acpi -t|awk \'{print $4}\'')
   fields = {temp:match((temp:gsub("[^"..'\n'.."]*"..'\n', "([^"..'\n'.."]*)"..'\n')))}
   temp=''
   local color
   for i in ipairs(fields) do
      if tonumber(fields[i]) < 50 then
         color = colors["normal"]
      elseif tonumber(fields[i]) >= 50 and tonumber(fields[i]) < 60 then
         color = colors["warm"]
      else
         color = colors["hot"]
      end
      temp = temp.." "..fields[i].." <span color=\""..color.."\">°C</span>"
   end
   temp = tostring(temp)
   widget.text = temp --_zone.." :: <span color=\""..color.."\">"..temp.."</span>"
end
update()

awful.hooks.timer.register(5, function () update() end)

setmetatable(_M, { __call = function () return widget end })

-- vim: filetype=lua:expandtab:shiftwidth=3:tabstop=3:softtabstop=3:encoding=utf-8:textwidth=80
