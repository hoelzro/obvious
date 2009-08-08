-----------------------------------
-- Author: Uli Schlachter        --
-- Copyright 2009 Uli Schlachter --
-----------------------------------

local beautiful = require("beautiful")
local awful = {
    widget = require("awful.widget")
}
local setmetatable = setmetatable

module("obvious.lib.widget.graph")

function graph(layout, scale)
    local theme = beautiful.get()
    local color = theme.progressbar_fg_color or theme.widget_fg_color or theme.fg_normal
    local back  = theme.progressbar_bg_color or theme.widget_bg_color or theme.bg_normal
    local border= theme.progressbar_border or theme.widget_border or theme.border_normal

    local widget = awful.widget.graph({ layout = layout })
    widget:set_color(color)
    widget:set_border_color(border)
    widget:set_background_color(back)

    if scale then
        widget:set_scale(true)
    end

    return widget
end

function create(data, layout)
    local scale = true
    if data.max then
        scale = false
    end

    local widget = graph(layout, scale)

    widget.update = function(widget)
        local max = widget.data.max or 1
        local val = widget.data:get() or max
        widget:add_value(val / max)
    end

    widget.data = data

    return widget
end

setmetatable(_M, { __call = function (_, ...) return graph(...) end })
-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:encoding=utf-8:textwidth=80