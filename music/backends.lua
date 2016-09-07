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
local mpris_backend = backend:clone { name = 'mpris' }

local backends = {
  mpd_backend,
  mpris_backend,
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

-- {{{ MPRIS backend

local NORMALIZED_MPRIS_STATES = {
  Playing = 'playing',
  Stopped = 'stopped',
  Paused  = 'paused',
}

function mpris_backend:configure()
  return self
end

function mpris_backend:ontrackchange(callback)
  local current_status = 'stopped'
  local current_metadata = {}

  dbus.add_match('session', "path='/org/mpris/MediaPlayer2',interface='org.freedesktop.DBus.Properties',member='PropertiesChanged'")
  dbus.connect_signal('org.freedesktop.DBus.Properties', function(metadata, name, payload)
    if name ~= 'org.mpris.MediaPlayer2.Player' then
      return
    end

    if payload.PlaybackStatus then
      current_status = NORMALIZED_MPRIS_STATES[payload.PlaybackStatus]
    end

    if payload.Metadata then
      current_metadata = {}
      for k, v in pairs(payload.Metadata) do
        if string.sub(k, 1, 6) == 'xesam:' then
          if type(v) == 'table' then
            v = table.concat(v, ' & ')
          end
          current_metadata[string.sub(k, 7)] = v
        end
      end
    end

    callback {
      state = current_status,
      info  = current_metadata,
    }
  end)

  callback {
    state = current_status,
    info  = current_metadata,
  }
end
-- }}}

local _M = {}

for i = 1, #backends do
  local backend = backends[i]
  _M[backend.name] = backend
end

return _M

-- vim:ft=lua:ts=2:sw=2:sts=2:tw=80:et:fdm=marker
