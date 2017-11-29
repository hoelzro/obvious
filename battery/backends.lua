--------------------------------------------
-- Author: Rob Hoelz                      --
-- Copyright 2015 Rob Hoelz               --
--------------------------------------------

local assert       = assert
local iopopen      = io.popen
local setmetatable = setmetatable
local tonumber     = tonumber
local tostring     = tostring
local floor        = math.floor
local sformat      = string.format
local smatch       = string.match
local unpack       = unpack or table.unpack

local backend = {}

local function popen(cmd)
  return iopopen('LC_ALL=C LANG=C ' .. cmd .. ' 2>/dev/null')
end

function backend:clone(clone)
  return setmetatable(clone or {}, { __index = self })
end

function backend:configure()
end

function backend:state()
end

function backend:details()
  local fd, err = self:details_pipe()

  if not fd then
    return nil, err
  end

  local d = fd:read('*all'):gsub('\n+$', '')
  fd:close()
  return d
end

local upower_backend      = backend:clone { name = 'upower' }
local acpiconf_backend    = backend:clone { name = 'acpiconf' }
local acpi_backend        = backend:clone { name = 'acpi' }
local acpitool_backend    = acpi_backend:clone { name = 'acpitool' }
local apm_backend         = backend:clone { name = 'apm' }
local apm_openbsd_backend = backend:clone { name = 'apm-openbsd' }
local null_backend        = backend:clone { name = 'null' }

local backends = {
  upower_backend,
  acpiconf_backend,
  acpi_backend,
  acpitool_backend,
  apm_backend,
  apm_openbsd_backend,
  null_backend,
}

local function default_configure(orig_backend)
  local backend = orig_backend:clone()
    local rv = backend:state()
    if next(rv) == nil then
      return nil
    end
    return backend
end

local function exists(name)
  local pipe = popen('which ' .. name)

  if not pipe then
    return false
  end

  local line = pipe:read '*l'
  pipe:close()

  return line and line ~= ''
end

local function defaults_to_key(t)
  local function return_key__index(_, key)
    return key
  end

  return setmetatable(t, { __index = return_key__index })
end

local function match_case(input, ...)
  local args = { ... }

  for i = 1, #args, 2 do
    local pattern = args[i]
    local action  = args[i + 1]

    local matches = { smatch(input, pattern) }

    if matches[1] then
      action(unpack(matches))
      break
    end
  end
end

-- XXX check for global usage
-- XXX rv is a bad variable name

-- {{{ upower backend

local upower_status_mapping = defaults_to_key {
  ['fully-charged'] = 'charged',
}

function upower_backend:configure()
  local fd, err = popen 'upower -e'
  if not fd then
    return nil, err
  end
  local battery_filenames = {}
  for line in fd:lines() do
    if line:match('battery_BAT') then
      battery_filenames[#battery_filenames + 1] = line
    end
  end
  fd:close()

  if #battery_filenames > 0 then
    return upower_backend:clone { filenames = battery_filenames }
  end
end

function upower_backend:state()
  local results = {}

  for i = 1, #self.filenames do
    local filename = self.filenames[i]

    local rv = {}
    local fd, err = popen('upower -i ' .. filename)

    if not fd then
      return nil, err
    end

    local function handle_time(time, units)
      if time == 'unknown' then
        time = nil
      elseif units == 'hour' or units == 'hours' then
        time = floor(time * 60)
      elseif units == 'minute' or units == 'minutes' then
        time = tonumber(floor(time))
      else
        time = 0
      end

      rv.time = time
    end

    for line in fd:lines() do
      match_case(line,
        '^%s*percentage:%s*(%d+)', function(charge)
          rv.charge = tonumber(charge)
        end,
        '%s*time to empty:%s*(%S+)%s*(%w*)', handle_time,
        '%s*time to full:%s*(%S+)%s*(%w*)', handle_time,
        'state:%s*(%S+)', function(status)
          rv.status = upower_status_mapping[status]
        end)
    end
    fd:close()
    results[i] = rv
  end

  return unpack(results)
end

function upower_backend:details()
  local results = ''

  for i = 1, #self.filenames do
    local filename = self.filenames[i]

    local pipe, err = popen('upower -i ' .. filename)

    if not pipe then
      return nil, err
    end

    local output = pipe:read '*a'
    results = results .. '\n' .. output:gsub('^\n', '')
  end

  return results
end
-- }}}

-- {{{ acpiconf backend
function acpiconf_backend:configure()
  return default_configure(acpiconf_backend)
end

local acpiconf_status_mapping = defaults_to_key {
  high = 'charged',
}

function acpiconf_backend:state()
  local rv = {}
  local fd, err = popen('acpiconf -i0')

  if not fd then
    return nil, err
  end

  for line in fd:lines() do
    match_case(line,
      '^Remaining capacity:%s*(%d+)', function(charge)
        rv.charge = tonumber(charge)
      end,
      '^Remaining time:%s*unknown', function()
        rv.time = nil
      end,
      '^Remaining time:%s*(%d+):(%d+)', function(hours, minutes)
        rv.time = tonumber(hours) * 60 + tonumber(minutes)
      end,
      '^State:%s*(%S+)', function(status)
        rv.status = acpiconf_status_mapping[status]
      end)
  end
  fd:close()
  return rv
end

function acpiconf_backend:details()
  local details = ''
  local fd, err = popen('acpiconf -i0')

  if not fd then
    return nil, err
  end

  for line in fd:lines() do
    details = details .. '\n' .. line
  end
  fd:close()
  return details:gsub('^\n', '')
end
-- }}}

-- {{{ acpitool backend
function acpitool_backend:configure()
  return default_configure(acpitool_backend)
end

acpitool_backend.backend = 'acpitool'
-- }}}

-- {{{ acpi backend
function acpi_backend:configure()
  return default_configure(acpi_backend)
end

function acpi_backend:state()
  local rv = {}
  local fd, err = popen(self.backend .. ' -b')

  if not fd then
    return nil, err
  end

  for line in fd:lines() do
    local data = line:match('Battery #?[0-9]%s*: ([^\n]*)')

    if not data then
      break
    end

    rv.status = data:match('([%a]*),.*'):lower()
    rv.charge = floor(tonumber(data:match('.*, (%d+%.?%d*)%%')))

    local hours, minutes = data:match('.*, (%d*):?(%d+):%d+')
    if hours or minutes then
      rv.time = (hours or 0) * 60 + minutes
    end

    if not rv.status:match('unknown') then
      break
    end
  end

  fd:close()

  return rv
end

function acpi_backend:details_pipe()
  return popen(self.backend)
end

acpi_backend.backend = 'acpi'
-- }}}

-- {{{ apm backend
function apm_backend:configure()
  if exists 'apm' then
    local fd, err = popen 'uname'
    if not fd then
      return nil, err
    end
    local os_name = fd:read '*l'
    fd:close()

    if os_name ~= 'OpenBSD' then
      return apm_backend:clone()
    end
  end
end

function apm_backend:state()
  local rv = {}
  local fd, err = popen 'apm'

  if not fd then
    return nil, err
  end

  local data = fd:read '*all'
  fd:close()

  if not data then return end

  rv.status  = data:match('battery ([a-z]+):')
  rv.charge  = tonumber(data:match('.*, .*: (%d+)%%'))
  rv.time    = data:match('%((.*)%)$')

  return rv
end

function apm_backend:details_pipe()
  return popen 'apm'
end
-- }}}

-- {{{ apm backend (OpenBSD)
function apm_openbsd_backend:configure()
  if exists 'apm' then
    local fd, err = popen 'uname'
    if not fd then
      return nil, err
    end
    local os_name = fd:read '*l'
    fd:close()

    if os_name == 'OpenBSD' then
      return apm_openbsd_backend:clone()
    end
  end
end

function apm_openbsd_backend:state()
  local rv = {}
  local fd, err = popen('apm -l -a -m')

  if not fd then
    return nil, err
  end

  local charge = fd:read '*l'
  local time   = fd:read '*l'
  local status = fd:read '*l'
  fd:close()

  if status == '0' then
    status = 'discharging'
  elseif status == '1' then
    status = 'charging'
  else
    status = 'unknown'
  end

  charge = tonumber(charge)

  if time == 'unknown' then
    time = nil
  else
    local hours   = tostring(floor(rv.time / 60 + 0.5)) -- XXX why the 0.5? (rounding up?)
    local minutes = tostring(rv.time % 60)

    time = sformat('%02d:%02d', hours, minutes)
  end

  -- XXX odd hack
  if charge >= 98 and status == 'charging' then
    status = 'full'
  end

  return {
    status = status,
    charge = charge,
    time   = time,
  }
end

function apm_openbsd_backend:details_pipe()
  return popen 'apm'
end
-- }}}

-- {{{ null backend
function null_backend:configure()
  return self
end

function null_backend:state()
  return nil
end

function null_backend:details()
  return 'unknown backend'
end
-- }}}

local function get(preferred_backend) -- {{{
  local backend

  if preferred_backend then
    for i = 1, #backends do
      if backends[i].name == preferred_backend then
        backend = backends[i]:configure()
      end
    end
  end

  if not backend then
    for i = 1, #backends do
      backend = backends[i]:configure()

      if backend then
        break
      end
    end
  end

  assert(backend, 'I should always fall back to the null backend!')

  return backend
end -- }}}

local _M = { get = get }

for i = 1, #backends do
  local backend = backends[i]
  _M[backend.name] = backend
end

return _M

-- vim:ft=lua:ts=2:sw=2:sts=2:tw=80:et:fdm=marker
