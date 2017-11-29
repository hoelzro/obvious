-------------------------------------------
-- Author: Gregor "farhaven" Best"       --
-- Copyright 2009 Gregor Best            --
-------------------------------------------

local obvious = require 'obvious.widget_registry'

obvious.basic_mpd        = require 'obvious.basic_mpd'
obvious.battery          = require 'obvious.battery'
obvious.clock            = require 'obvious.clock'
obvious.cpu              = require 'obvious.cpu'
obvious.fs_usage         = require 'obvious.fs_usage'
obvious.io               = require 'obvious.io'
obvious.lib              = require 'obvious.lib'
obvious.loadavg          = require 'obvious.loadavg'
obvious.mem              = require 'obvious.mem'
obvious.net              = require 'obvious.net'
obvious.popup_run_prompt = require 'obvious.popup_run_prompt'
obvious.umts             = require 'obvious.umts'
obvious.volume_alsa      = require 'obvious.volume_alsa'
obvious.volume_freebsd   = require 'obvious.volume_freebsd'
obvious.wlan             = require 'obvious.wlan'
obvious.temp_info        = require 'obvious.temp_info'
obvious.keymap_switch    = require 'obvious.keymap_switch'
obvious.weather          = require 'obvious.weather'
obvious.music            = require 'obvious.music'

local naughty = require 'naughty'

local function warn(msg)
  naughty.notify {
    title   = 'Obvious warning',
    text    = msg,
    timeout = 0,
    preset  = naughty.config.presets.warn,
  }
end

local warning_metatable = {}

function warning_metatable:__index(key)
  local module_name = 'obvious.' .. key
  local caller_info = debug.getinfo(2, 'nSl')
  local source = caller_info.source

  if string.sub(source, 1, 1) == '@' then
    source = string.sub(source, 2)
  else
    source = '<chunk>'
  end

  local location = string.format('%s:%d %s %s', source, caller_info.currentline, caller_info.namewhat, caller_info.name)

  warn(string.format("You tried to use %q as an old-style Lua module at %s; from now on you'll want to do local %s = require(%q) instead", module_name, location, key, module_name))
  rawset(self, key, obvious[key]) -- set the value on this table so that __index (and thus the warning) isn't called for this key again
  return obvious[key]
end

local warning_table = setmetatable({}, warning_metatable)

_G.obvious = warning_table

return obvious

-- vim:ft=lua:ts=2:sw=2:sts=2:tw=80:et
