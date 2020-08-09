-----------------------------------
-- Author: Uli Schlachter        --
-- Copyright 2009 Uli Schlachter --
-----------------------------------

local widgets_by_type = {
  graph       = require 'obvious.lib.widget.graph',
  progressbar = require 'obvious.lib.widget.progressbar',
  textbox     = require 'obvious.lib.widget.textbox',
}

local setmetatable = setmetatable
local getmetatable = getmetatable
local pairs = pairs
local type = type
local lib = {
  hooks = require("obvious.lib.hooks")
}

local defaults = { }

-- The functions each object from from_data_source will get
local funcs = { }

funcs.set_type = function (obj, widget_type)
  local widget_type = widgets_by_type[widget_type]
  if not widget_type or not widget_type.create then
    return
  end

  local meta = getmetatable(obj)

  local widget = widget_type.create(meta.data)
  obj[1] = widget
  obj.update()
  return obj
end

local function from_data_source(data)
  local ret = { }

  for k, v in pairs(funcs) do
    ret[k] = v
  end

  -- We default to graph since progressbars can't handle sources without an
  -- upper bound on their value
  ret[1] = widgets_by_type.graph.create(data)

  ret.update = function()
    -- because this uses ret, if ret[1] is changed this automatically
    -- picks up the new widget
    ret[1]:update()
  end

  -- Fire up the timer which keeps this widget up-to-date
  lib.hooks.timer.register(10, 60, ret.update)
  lib.hooks.timer.start(ret.update)
  ret.update()

  local meta = { }

  meta.data = data

  -- This is called when an unexesting key is accessed
  meta.__index = function (obj, key)
    local ret = obj[1][key]
    if key ~= "layout" and type(ret) == "function" then
      -- Ugly hack: this function wants to be called on the right object
      return function(_, ...)
        -- Ugly hack: this function wants to be called on the right object
        return ret(obj[1], ...)
      end
    end
    return ret
  end

  setmetatable(ret, meta)
  return ret
end

return {
  from_data_source = from_data_source,
}

-- vim:ft=lua:ts=2:sw=2:sts=2:tw=80:et
