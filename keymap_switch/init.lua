---------------------------------
-- Author: Andrei Thorp        --
-- Copyright 2010 Andrei Thorp --
---------------------------------
-- depends on setxkbmap
-- Ideas:
-- * user specified rewrite table: convert us(dvorak) to "Dvorak"
-- * use formatting system to allow people to format their text widgets
-- * allow the user to override the text widget with some other widget
-- * implement on-click (or bindable) menu that will list currently
--   configured and available layouts that aren't the current one

local setmetatable = setmetatable
local widget = widget
local io = {
    popen = io.popen
}
local awful = require("awful")
local lib = {
    hooks = require("obvious.lib.hooks"),
    markup = require("obvious.lib.markup")
}

module("obvious.keymap_switch")

panelwidget = widget({ type = "textbox" })
panelwidget.text = "determining layout..."

local function get_current_keymap()
    local fd = io.popen("setxkbmap -print")
    if not fd then return end

    for line in fd:lines() do
        if line:match("xkb_symbols") then
            keymap = line:match("\+.*\+")

            if not keymap then
                return "unknown layout"
            else
                return keymap:sub(2, -2)
            end
        end
    end

    return "unknown layout"
end

function update()
    panelwidget.text = get_current_keymap()
end

lib.hooks.timer.register(5, 60, update, "Update for the keymap widget")
lib.hooks.timer.start(update)
-- Can't update right away. Probably setxkbmap is fubar somehow.

setmetatable(_M, { __call = function() return panelwidget end})
-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=4:softtabstop=4:encoding=utf-8:textwidth=80
