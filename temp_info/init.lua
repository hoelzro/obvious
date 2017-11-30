-----------------------------------
-- Author: Eligio Becerra        --
-- Copyright 2009 Eligio Becerra --
-----------------------------------

local setmetatable = setmetatable
local tonumber     = tonumber
local sformat      = string.format
local smatch       = string.match
local sgmatch      = string.gmatch
local popen        = io.popen
local ipairs       = ipairs
local wibox        = require 'wibox'
local markup       = require 'obvious.lib.markup'
local hooks        = require 'obvious.lib.hooks'

local temperature = {}

local widget = wibox.widget.textbox()

local colors = {
   normal = '#009000',
   warm   = '#909000',
   hot    = '#900000',
}

local function pread(cmd)
  local pipe = popen(cmd)
  if not pipe then
    return ''
  end
  local results = pipe:read '*a'
  pipe:close()
  return results
end

local function acpi_backend()
   local d    = pread 'acpi -t'
   local temp = {}
   for t in sgmatch(d, 'Thermal %d+: %w+, (%d+.?%d*) degrees') do
      temp[#temp + 1] = tonumber(t)
   end

   if #temp == 0 then
      return
   end

   return temp
end

local function sensors_backend()
   local pipe          = popen('sensors -u', 'r')
   local in_temp_block = false
   local stats         = {}

   if not pipe then
      return
   end

   -- we assume that the first temp1 block is the CPU, and that
   -- the CPU stats are under temp1
   for line in pipe:lines() do
     if line == 'temp1:' then
       in_temp_block = true
     elseif in_temp_block then
       if line == '' then
         break
       end
       local name, value = smatch(line, '^%s*temp1_(%w+):%s+(.+)')
       if name and value then
         stats[name] = tonumber(value)
       end
     end
   end

   if stats.input then
      return { stats.input }
   else
      return
   end
end

local function noop_backend()
   return {}
end

local backends = {
   acpi_backend,
   sensors_backend,
   noop_backend,
}
local current_backend

local function find_backend()
   if current_backend then
      return current_backend
   end

   for _, backend in ipairs(backends) do
      local stats = backend()
      if stats then
         current_backend = backend
         break
      end
   end
end

local function update()
   local temp = current_backend()

   local color = colors.hot
   if not temp[1] then
      widget:set_text 'no data'
      return
   end
   if temp[1] < 50 then
      color = colors.normal
   elseif temp[1] >= 50 and temp[1] < 60 then
      color = colors.warm
   end
   widget:set_markup(sformat('%.2f', temp[1]) .. ' ' .. markup.fg.color(color, 'C'))
end

hooks.timer.register(5, 30, update)
hooks.timer.stop(update)

setmetatable(temperature, { __call = function ()
   find_backend()
   hooks.timer.start(update)
   update()
   return widget
end })

require('obvious.widget_registry').temp_info = temperature
return temperature

-- vim: filetype=lua:expandtab:shiftwidth=3:tabstop=3:softtabstop=3:textwidth=80
