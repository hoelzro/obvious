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

return obvious

-- vim:ft=lua:ts=2:sw=2:sts=2:tw=80:et
