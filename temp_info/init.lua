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
local wibox        = require 'wibox'
local markup       = require 'obvious.lib.markup'
local hooks        = require 'obvious.lib.hooks'
local async        = require 'obvious.lib.async'
local spawn        = require 'awful.spawn'

module 'obvious.temp_info'

local widget = wibox.widget.textbox()

local colors = {
   normal = '#009000',
   warm   = '#909000',
   hot    = '#900000',
}
local function acpi_backend(callback)
   spawn.easy_async('acpi -t',
                    function(stdout, stderr, reason, exit_code)
                       local temp = {}
                       for t in sgmatch(stdout, 'Thermal %d+: %w+, (%d+.?%d*) degrees') do
                          temp[#temp + 1] = tonumber(t)
                       end

                       if #temp == 0 then
                          return callback()
                       end

                       return callback(temp)
                    end
   )
end

local function sensors_backend(callback)
   local pipe          = popen('sensors -u', 'r')
   local in_temp_block = false
   local stats         = {}

   if not pipe then
      return callback()
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
      return callback({ stats.input })
   else
      return callback()
   end
end

local function noop_backend(callback)
   return callback({})
end

local backends = {
   acpi_backend,
   sensors_backend,
   noop_backend,
}
local current_backend

local function find_backend(callback)
   if current_backend then
      return callback(current_backend)
   end
   async.find(backends,
              function(backend)
                 current_backend = backend
                 callback(current_backend)
   end)
end

local function update()
   current_backend(function(temp)
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
   end)
end

hooks.timer.register(5, 30, update)
hooks.timer.stop(update)

setmetatable(_M, { __call = function ()
                      find_backend(function()
                            hooks.timer.start(update)
                            update()
                      end)
                      return widget
end })

-- vim: filetype=lua:expandtab:shiftwidth=3:tabstop=3:softtabstop=3:textwidth=80
