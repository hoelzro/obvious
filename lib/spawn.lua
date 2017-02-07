local assert = assert
local awful = require 'awful'
local coroutine = coroutine

module 'obvious.lib.spawn'

function read_all(command)
  local coro = assert(coroutine.running(), "you can't call read_all from main coroutine")

  -- XXX handle errors
  awful.spawn.easy_async(command, function(stdout)
    coroutine.resume(coro, stdout)
  end)

  return coroutine.yield()
end
