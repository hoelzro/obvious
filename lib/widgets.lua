-----------------------------------
-- Author: Uli Schlachter        --
-- Copyright 2009 Uli Schlachter --
-----------------------------------

local beautiful = require("beautiful")
local awful = {
    widget = require("awful.widget")
}

module("obvious.lib.widgets")

function progressbar(layout)
    local theme = beautiful.get()
    local width = theme.progressbar_width or theme.widget_width or 8
    local color = theme.progressbar_fg_color or theme.widget_fg_color or theme.fg_normal
    local back  = theme.progressbar_bg_color or theme.widget_bg_color or theme.bg_normal
    local border= theme.progressbar_border or theme.widget_border or theme.border_normal

    local widget = awful.widget.progressbar({ layout = layout })
    widget:set_vertical(true)

    widget:set_width(width)
    widget:set_color(color)
    widget:set_background_color(back)
    widget:set_border_color(border)

    return widget
end

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:encoding=utf-8:textwidth=80
