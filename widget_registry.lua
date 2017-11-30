local registry = {}

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
  rawset(self, key, registry[key]) -- set the value on this table so that __index (and thus the warning) isn't called for this key again
  return registry[key]
end

local warning_table = setmetatable({}, warning_metatable)

_G.obvious = warning_table

return registry
