--------------------------------------------
-- Author: Rob Hoelz                      --
-- Copyright 2016 Rob Hoelz               --
--------------------------------------------

local mpd   = require 'obvious.lib.mpd'
local hooks = require 'obvious.lib.hooks'

-- {{{ Abstract Backend Object
local backend = {}

function backend:clone(clone)
  return setmetatable(clone or {}, { __index = self })
end

function backend:configure()
end

function backend:ontrackchange(callback)
end

-- }}}

local mpd_backend = backend:clone { name = 'mpd' }

local backends = {
  mpd_backend,
}

-- {{{ MPD backend

local NORMALIZED_MPD_STATES = {
  play  = 'playing',
  stop  = 'stopped',
  pause = 'paused',
}

function mpd_backend:configure()
  local connection = mpd.new()

  return mpd_backend:clone {
    connection = connection,
  }
end

function mpd_backend:ontrackchange(callback)
  local prev_state
  local prev_songid

  local function update()
    local status = self.connection:send 'status'

    if prev_state == status.state and prev_songid == status.songid then
      return
    end

    if not status.state then -- MPD isn't running
      callback(nil)
    else
      callback {
        state = NORMALIZED_MPD_STATES[status.state],
        info = self.connection:send 'currentsong',
      }
    end

    prev_state  = status.state
    prev_songid = status.songid
  end

  hooks.timer.register(1, 30, update, 'basic_mpd widget refresh rate')
end

-- }}}

local _M = {}

for i = 1, #backends do
  local backend = backends[i]
  _M[backend.name] = backend
end

return _M

-- vim:ft=lua:ts=2:sw=2:sts=2:tw=80:et:fdm=marker
