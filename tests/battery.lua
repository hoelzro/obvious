-- vim:ft=lua:ts=2:sw=2:sts=2:tw=80:et:fdm=marker

local charged_output = { -- {{{
  ['upower -e'] = [[
/org/freedesktop/UPower/devices/line_power_AC
/org/freedesktop/UPower/devices/battery_BAT0
/org/freedesktop/UPower/devices/DisplayDevice
  ]],

  ['upower -i /org/freedesktop/UPower/devices/battery_BAT0'] = [[
  native-path:          BAT0
  vendor:               SMP
  model:                DELL TXWRR2C
  serial:               484
  power supply:         yes
  updated:              Wed 11 Nov 2015 10:59:41 AM CST (73 seconds ago)
  has history:          yes
  has statistics:       yes
  battery
    present:             yes
    rechargeable:        yes
    state:               fully-charged
    warning-level:       none
    energy:              58.0216 Wh
    energy-empty:        0 Wh
    energy-full:         58.0216 Wh
    energy-full-design:  58.1555 Wh
    energy-rate:         0.011158 W
    voltage:             12.277 V
    percentage:          100%
    capacity:            55.5641%
    technology:          lithium-ion
    icon-name:          'battery-full-charged-symbolic'
  ]],

  ['acpi -b'] = [[
Battery 0: Charged, 100%
  ]],

  ['acpi'] = [[
Battery 0: Charged, 100%
  ]],

  ['acpitool -b'] = [[
  Battery #1     : Charged, 100.0%, 5200:00:00
  ]],

  ['acpitool'] = [[
  Battery #1     : Charged, 100.0%, 5200:00:00
  AC adapter     : <info not available> 
  Thermal info   : <not available>
  ]],

  ['apm -l -a -m'] = [[
100
unknown
1
  ]],
  ['apm'] = [[
Battery state: high, 100% remaining
A/C adapter state: connected
Performance adjustment mode: manual (2531 MHz)
  ]],
} -- }}}

local discharging_output = { -- {{{
  ['upower -e'] = charged_output['upower -e'],
  ['upower -i /org/freedesktop/UPower/devices/battery_BAT0'] = [[
  native-path:          BAT0
  vendor:               SMP
  model:                DELL TXWRR2C
  serial:               484
  power supply:         yes
  updated:              Wed 11 Nov 2015 11:23:41 AM CST (76 seconds ago)
  has history:          yes
  has statistics:       yes
  battery
    present:             yes
    rechargeable:        yes
    state:               discharging
    warning-level:       none
    energy:              26.7346 Wh
    energy-empty:        0 Wh
    energy-full:         58.0216 Wh
    energy-full-design:  58.1555 Wh
    energy-rate:         45.4465 W
    voltage:             10.587 V
    time to empty:       35.3 minutes
    percentage:          72%
    capacity:            55.5641%
    technology:          lithium-ion
    icon-name:          'battery-full-symbolic'
  History (charge):
    1447262621	72.000	discharging
  History (rate):
    1447262621	45.447	discharging
  ]],
  ['acpi -b'] = [[
Battery 0: Discharging, 72%, 00:32:23 remaining
  ]],
  ['acpi'] = [[
Battery 0: Discharging, 72%, 00:32:50 remaining
  ]],
  ['acpitool -b'] = [[
  Battery #1     : Discharging, 72.80%, 00:31:11
  ]],
  ['acpitool'] = [[
  Battery #1     : Discharging, 72.69%, 00:32:17
  AC adapter     : <info not available> 
  Thermal info   : <not available>
  ]],
  ['apm -l -a -m'] = [[
73
37
0
  ]],
  ['apm'] = [[
Battery state: high, 72% remaining, 38 minutes life estimate
A/C adapter state: not connected
Performance adjustment mode: manual (2531 MHz)
  ]],
} -- }}}

local charging_output = { -- {{{
  ['upower -e'] = charged_output['upower -e'],
  ['upower -i /org/freedesktop/UPower/devices/battery_BAT0'] = [[
  native-path:          BAT0
  vendor:               SMP
  model:                DELL TXWRR2C
  serial:               484
  power supply:         yes
  updated:              Wed 11 Nov 2015 11:29:41 AM CST (88 seconds ago)
  has history:          yes
  has statistics:       yes
  battery
    present:             yes
    rechargeable:        yes
    state:               charging
    warning-level:       none
    energy:              22.9408 Wh
    energy-empty:        0 Wh
    energy-full:         58.0216 Wh
    energy-full-design:  58.1555 Wh
    energy-rate:         21.5126 W
    voltage:             11.894 V
    time to full:        1.6 hours
    percentage:          72%
    capacity:            55.5641%
    technology:          lithium-ion
    icon-name:          'battery-full-charging-symbolic'
  History (rate):
    1447262981	21.513	charging
  ]],
  ['acpi -b'] = [[
Battery 0: Charging, 72%, 00:24:33 until charged
  ]],
  ['acpi'] = [[
Battery 0: Charging, 72%, 00:24:31 until charged
  ]],
  ['acpitool -b'] = [[
  Battery #1     : Charging, 72.96%, 01:05:55
  ]],
  ['acpitool'] = [[
  Battery #1     : Charging, 73.07%, 01:06:01
  AC adapter     : <info not available> 
  Thermal info   : <not available>
  ]],
  ['apm'] = [[
70
38
1
  ]],
} -- }}}

-- {{{ mock setup
for _, output_table in ipairs { charged_output, discharging_output, charging_output } do
  for key, output in pairs(output_table) do
    local trimmed_output = string.match(output, '^%s*(.-)%s*$')
    output_table[key] = trimmed_output .. '\n'
  end
end

local mock_output = {
  charged     = charged_output,
  discharging = discharging_output,
  charging    = charging_output,
}

local smatch   = string.match
local itmpfile = io.tmpfile
local sformat  = string.format

local ac_state = 'charged'

local function mock_popen(command)
  local which_match = smatch(command, '^which%s+(%w+)')
  local output

  if which_match then
    output = '/usr/bin/' .. which_match
  else
    local output_lookup = mock_output[ac_state]
    output = output_lookup[command]
  end

  if not output then
    return nil, 'No output for command ' .. command
  end

  local fh = assert(itmpfile())

  fh:write(output)
  assert(fh:seek 'set')

  return fh
end

io.popen = mock_popen
-- }}}

local backends = require 'battery.backends'

local blacklisted_backends = {
  acpiconf        = true, -- XXX gather acpiconf data from FreeBSD
  ['apm-openbsd'] = true, -- XXX mock uname command
  apm             = true, -- XXX need to find a working version of APM
  null            = true, -- null backend has different state
}

for name, backend_proto in pairs(backends) do
  if name ~= 'get' and not blacklisted_backends[name] then
    local backend = backend_proto:configure()

    assert(backend, 'backend ' .. name .. ' should be defined')

    local state = backend:state()
    local details = backend:details()

    assert(state ~= nil, sformat("backend: %s state should not be nil", name))
    assert(state.status == 'charged', sformat("backend: %s status should be 'charged', is %s", name, tostring(state.status)))
    assert(state.charge == 100, sformat("backend: %s charge should be 100, is %d", name, state.charge))
    -- XXX percentage
    assert(type(details) == 'string', sformat("backend: %s details should be a string", name))
    assert(details ~= '', sformat("backend- %s details should be a non-empty string", name))
  end
end

ac_state = 'charging'

for name, backend_proto in pairs(backends) do
  if name ~= 'get' and not blacklisted_backends[name] then
    local backend = backend_proto:configure()

    assert(backend, 'backend ' .. name .. ' should be defined')

    local state = backend:state()
    local details = backend:details()

    assert(state ~= nil, sformat("backend: %s state should not be nil", name))
    assert(state.status == 'charging', sformat("backend: %s status should be 'charging', is %s", name, tostring(state.status)))
    assert(state.charge == 72, sformat("backend: %s charge should be 72, is %s", name, tostring(state.charge)))
    -- XXX time
    assert(type(details) == 'string', sformat("backend: %s details should be a string", name))
    assert(details ~= '', sformat("backend- %s details should be a non-empty string", name))
  end
end

ac_state = 'discharging'

for name, backend_proto in pairs(backends) do
  if name ~= 'get' and not blacklisted_backends[name] then
    local backend = backend_proto:configure()

    assert(backend, 'backend ' .. name .. ' should be defined')

    local state = backend:state()
    local details = backend:details()

    assert(state ~= nil, sformat("backend: %s state should not be nil", name))
    assert(state.status == 'discharging', sformat("backend: %s status should be 'charging', is %s", name, tostring(state.status)))
    assert(state.charge == 72, sformat("backend: %s charge should be 72, is %s", name, tostring(state.charge)))
    -- XXX time
    assert(type(details) == 'string', sformat("backend: %s details should be a string", name))
    assert(details ~= '', sformat("backend- %s details should be a non-empty string", name))
  end
end

-- XXX handle failure
-- XXX handle unknown
-- XXX handle each backend
-- XXX handle backend detection
-- XXX handle preferred backend
-- XXX apciconf, apm (non-OpenBSD) output
-- XXX how to distinguish OpenBSD vs non for output?
-- XXX verify apm OpenBSD charged output
-- XXX handle lack of command
