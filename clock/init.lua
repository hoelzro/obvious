--------------------------------
-- Author: Gregor Best        --
-- Copyright 2009 Gregor Best --
--------------------------------

local pairs = pairs
local print = print
local setmetatable = setmetatable
local tonumber = tonumber
local os = {
    date = os.date
}
local io = {
    lines = io.lines
}
local string = {
    match = string.match
}
local table = {
    insert = table.insert
}
local capi = {
    widget = widget,
    button = button,
    mouse = mouse
}

local awful = require("awful")
local beautiful = require("beautiful")
local naughty = require("naughty")

module("obvious.clock")

local menu
local editor = "xmessage 'Set your editor with widgets.clock.set_editor(\"editor\")'; echo"

local function edit(file)
    print("running "..editor.." to edit "..file)
    awful.util.spawn(editor .. " " .. file)
end

local alarmfile = awful.util.getdir("config").."/alarms"

local fulldate = false
local alarms = { }

local widget = capi.widget({
        type = "textbox",
        name = "clock",
        align = "right"
    })

widget:buttons({
    capi.button({ }, 3, function ()
        menu:toggle()
    end), 
    capi.button({ }, 1, function ()
        if #alarms > 0 then
            for k, v in pairs(alarms) do
                naughty.notify({ text = v,
                                 screen = capi.mouse.screen
                })
            end
            alarms = { }
            widget.bg = beautiful.bg_normal
        else
            naughty.notify({ text = awful.util.pread("ddate"), width = 360 })
        end
    end)
})

local function update (trigger_alarms)
    local date
    if not fulldate then
        date = os.date("%H:%M (") .. (tonumber(os.date("%W")) + 1)..") "
    else
        date = os.date() .. " "
    end
    
    if #alarms > 0 then
        date = "<span color='" .. beautiful.fg_focus .. "'>"..date.."</span>"
        widget.bg = beautiful.bg_focus
    else
        widget.bg = beautiful.bg_normal
    end
    
    widget.text = "<span color=\"#00FF00\">⚙</span> " .. date
    
    if trigger_alarms then
        for line in io.lines(alarmfile) do
            if string.match(line, "^"..os.date("%H:%M")) then
                naughty.notify({ text = line,
                                 screen = capi.mouse.screen
                               })
                local add = true
                for _, v in pairs(alarms) do
                    if v == line then
                        add = false
                        break
                    end
                end
                if add then table.insert(alarms, line) end
            end
        end
        update(false)
    end
end

function set_editor(e)
    editor = e
end

widget.mouse_enter = function ()
    fulldate = true
    update(false)
end

widget.mouse_leave = function ()
    fulldate = false
    update(false)
end

setmetatable(_M, { __call = function () 
    update(true)
    awful.hooks.timer.register(60, function() update(true) end)

    menu = awful.menu.new({
        id = "clock",
        items = {
            { "edit todo", function () edit("~/todo") end },
            { "edit alarms", function () edit(alarmfile) end }
        }
    })

    return widget
end })
