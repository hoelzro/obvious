-----------------------------------
-- Author: Uli Schlachter        --
-- Copyright 2009 Uli Schlachter --
-----------------------------------

local type = type
local margins = awful.widget.layout.margins
local capi = {
    widget = widget
}
local string = {
    format = string.format
}

module("obvious.lib.widget.textbox")

function create(data, layout)
    local obj = { }

    obj.data = data
    obj.widget = capi.widget({ type = "textbox" })
    obj.format = "%3d%%"
    obj.layout = layout

    obj.update = function(obj)
        local max = obj.data.max or 1
        local val = obj.data:get() or max
        local perc = val / max * 100
        if type(obj.format) == "function" then
            obj.widget.text = obj.format(perc)
        else
            obj.widget.text = string.format(obj.format, perc)
        end
    end

    obj.set_format = function(obj, format)
        obj.format = format
        obj:update()
        return obj
    end

    obj.set_margin = function(obj, margin)
        margins[obj.widget] = margin
        return obj
    end

    return obj
end

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:encoding=utf-8:textwidth=80
