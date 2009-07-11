-- Small interface to MusicPD
-- based on a netcat version from Steve Jothen <sjothen at gmail dot com>
-- (see http://github.com/otkrove/ion3-config/tree/master/mpd.lua)
--
-- Copyright (c) 2008-2009, Alexandre Perrin <kaworu@kaworu.ch>
-- All rights reserved.
--
-- Redistribution and use in source and binary forms, with or without
-- modification, are permitted provided that the following conditions
-- are met:
--
-- 1. Redistributions of source code must retain the above copyright
--    notice, this list of conditions and the following disclaimer.
-- 2. Redistributions in binary form must reproduce the above copyright
--    notice, this list of conditions and the following disclaimer in the
--    documentation and/or other materials provided with the distribution.
-- 4. Neither the name of the author nor the names of its contributors
--    may be used to endorse or promote products derived from this software
--    without specific prior written permission.
--
-- THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
-- ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
-- IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
-- ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
-- FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
-- DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
-- OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
-- HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
-- LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
-- OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
-- SUCH DAMAGE.

require("socket")

-- Grab env
local socket = socket
local string = string
local tonumber = tonumber

-- Music Player Daemon Lua library.
module("obvious.lib.mpd")

-- default settings values
settings =
{
  hostname = "localhost",
  port = 6600,
  password = nil,
}

-- our socket
local sock = nil;

-- override default settings values
function setup(hostname, port, password)
  settings.hostname = hostname
  settings.port = port
  settings.password = password
  -- Unset this so that next operation knows to
  -- get a different server
  sock = nil
end


-- calls the action and returns the server's response.
--      Example: if the server's response to "status" action is:
--              volume: 20
--              repeat: 0
--              random: 0
--              playlist: 599
--              ...
--      then the returned table is:
--      { volume = 20, repeat = 0, random = 0, playlist = 599, ... }
function send(action)
  local command = string.format("%s\n", action)
  local values = {}

  -- connect to MPD server if not already done.
  if not sock then
    sock = socket.connect(settings.hostname, settings.port)
    if sock and settings.password then
      send(string.format("password %s", settings.password))
    end
  end

  if sock then
    sock:send(command)
    local line = sock:receive("*l")

    if not line then -- closed (mpd killed?): reset socket and retry
      sock = nil
      return send(action)
    end

    while not (line:match("^OK$") or line:match(string.format("unknow command \"%s\"", action))) do
      local _, _, key, value = string.find(line, "(.+):%s(.+)")
      if key then
        values[string.lower(key)] = value
      end
      line = sock:receive("*l")
    end
  end

  return values
end

function next()
  send("next")
end

function previous()
  send("previous")
end

function pause()
  send("pause")
end

function stop()
  send("stop")
end

-- no need to check the new value, mpd will set the volume in [0,100]
function volume_up(delta)
  local stats = send("status")
  local new_volume = tonumber(stats.volume) + delta
  send(string.format("setvol %d", new_volume))
end

function volume_down(delta)
  volume_up(-delta)
end

function toggle_random()
  local stats = send("status")
  if tonumber(stats.random) == 0 then
    send("random 1")
  else
    send("random 0")
  end
end

function toggle_repeat()
  local stats = send("status")
  if tonumber(stats["repeat"]) == 0 then
    send("repeat 1")
  else
    send("repeat 0")
  end
end

function toggle_play()
  if send("status").state == "stop" then
    send("play")
  else
    send("pause")
  end
end

-- vim:filetype=lua:tabstop=8:shiftwidth=2:fdm=marker:
