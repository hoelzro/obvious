--------------------------------------------
-- Author: Gregor Best                    --
-- Copyright 2009, 2010, 2011 Gregor Best --
--------------------------------------------

local string = {
  format = string.format
}
local lib = {
  widget = require("obvious.lib.widget"),
  markup = require("obvious.lib.markup"),
  wlan   = require("obvious.lib.wlan")
}

local function format_percent(link)
  local color = "#009000"
  if link < 50 and link > 10 then
    color = "#909000"
  elseif link <= 10 then
    color = "#900000"
  end
  return lib.markup.fg.color(color,"☢") .. string.format(" %03d%%", link)
end

local function get_data_source(device)
  local device = device
  if device == "auto" then
    device = lib.wlan.find_first_wlan()
  end
  device = device or "wlan0"

  local data = {}

  data.device = device
  data.max = 100
  data.get = function (obj)
    return lib.wlan(obj.device)
  end

  local ret = lib.widget.from_data_source(data)
  -- Due to historic reasons, this widget defaults to a textbox with
  -- a "special" format.
  ret:set_type("textbox")
  ret:set_format(format_percent)

  return ret
end

return setmetatable({}, { __call = function (_, ...) return get_data_source(...) end })

-- vim:ft=lua:ts=2:sw=2:sts=2:tw=80:et
