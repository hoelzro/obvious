local glib = require('lgi').GLib
local cqueues = require 'cqueues'

local controller = cqueues.new()

local controller_fd = controller:pollfd()
local events = controller:events()

assert(type(controller_fd) == 'number')

local conditions = 0

if string.find(events, 'r') then
  conditions = conditions | glib.IOCondition.IN
end

if string.find(events, 'w') then
  conditions = conditions | glib.IOCondition.OUT
end

if string.find(events, 'p') then
  conditions = conditions | glib.IOCondition.PRI
end

assert(conditions ~= 0)

local timeout_source_id

local refresh_timeout
function refresh_timeout()
  if timeout_source_id then
    glib.source_remove(timeout_source_id)
    timeout_source_id = nil
  end

  local timeout = controller:timeout()
  if timeout then
    timeout_source_id = glib.timeout_add(glib.PRIORITY_DEFAULT, 1000 * timeout, function()
      local ok, err = controller:step(0)
      refresh_timeout()
      if not ok then
        -- XXX could we do better here?
        print(err)
      end
      return false
    end)
  end
end

local poll_channel = glib.IOChannel.unix_new(controller_fd)
glib.io_add_watch(poll_channel, glib.PRIORITY_DEFAULT, conditions, function()
  local ok, err = controller:step(0)
  refresh_timeout()
  if not ok then
    -- XXX could we do better here?
    print(err)
  end

  return true
end)

local function run_cqueues(fn, callback)
  controller:wrap(function()
    callback(pcall(fn))
    refresh_timeout()
  end)
end

return run_cqueues
