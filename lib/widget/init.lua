-----------------------------------
-- Author: Uli Schlachter        --
-- Copyright 2009 Uli Schlachter --
-----------------------------------

require("obvious.lib.widget.graph")
require("obvious.lib.widget.progressbar")
require("obvious.lib.widget.textbox")

local setmetatable = setmetatable
local getmetatable = getmetatable
local pairs = pairs
local type = type
local lib = {
    hooks = require("obvious.lib.hooks")
}
local layout = require("awful.widget.layout.horizontal")

module("obvious.lib.widget")


local defaults = { }
set_default_layout = function(lay)
    defaults.layout = lay or layouts.leftright
end

set_default_margin = function(marg)
    defaults.margin = marg or { left = 5 }
end

-- The functions each object from from_data_source will get
local funcs = { }

funcs.set_type = function (obj, widget_type)
    local widget_type = _M[widget_type]
    if not widget_type or not widget_type.create then
        return
    end

    local meta = getmetatable(obj)

    local widget = widget_type.create(meta.data, defaults.layout)
    obj[1] = widget
    obj.update()
    obj:set_margin(defaults.margin)

    return obj
end

funcs.set_layout = function (obj, layout)
    obj[1].layout = layout
    obj.layout = layout
    obj:set_margin(defaults.margin)
    return obj
end

funcs.set_margin = function (obj, margin)
    obj[1]:set_margin(margin)
    return obj
end

function from_data_source(data)
    local ret = { }

    for k, v in pairs(funcs) do
        ret[k] = v
    end

    -- We default to graph since progressbars can't handle sources without an
    -- upper bound on their value
    ret[1] = _M.graph.create(data)
    ret.layout = nil

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
                ret(obj[1], ...)
                -- Ugly hack 2: We force obj to be returned again and discard
                -- the function's return value
                return obj
            end
        end
        return ret
    end

    -- Default layout is leftright, users can override this if they want to
    ret:set_layout(defaults.layout)

    setmetatable(ret, meta)
    return ret
end

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:encoding=utf-8:textwidth=80
