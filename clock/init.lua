--------------------------------
-- Author: Gregor Best        --
-- Copyright 2009 Gregor Best --
--------------------------------

local pairs = pairs
local print = print
local setmetatable = setmetatable
local tonumber = tonumber
local type = type
local os = {
    date = os.date,
    getenv = os.getenv
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
    mouse = mouse,
    screen = screen
}
local awful = require("awful")
local beautiful = require("beautiful")
local naughty = require("naughty")

module("obvious.clock")

local defaults = { }
defaults.shorttimeformat = "%T"
defaults.longtimeformat = "%T %D"
defaults.editor = "xmessage 'Set your editor with widgets.clock.set_editor(\"editor\")'; echo"
local settings = { }
for key, value in pairs(defaults) do
    settings[key] = value
end

local menu

local function edit(file)
    print("running " .. settings.editor .. " to edit " .. file)
    awful.util.spawn(settings.editor .. " " .. file)
end

local alarmfile = awful.util.getdir("config").."/alarms"

local fulldate = false
local alarms = { }

local widget = capi.widget({
        type = "textbox",
        name = "clock",
        align = "right"
    })

widget:buttons(awful.util.table.join(
    awful.button({ }, 3, function ()
        menu:toggle()
    end), 
    awful.button({ }, 1, function ()
        if #alarms > 0 then
            for _, v in pairs(alarms) do
                naughty.notify({ text = v[2],
                                 title = v[1],
                                 screen = capi.mouse.screen
                })
            end
            alarms = { }
            widget.bg = beautiful.bg_normal
        else
            naughty.notify({ text = awful.util.pread("ddate"), width = 360 })
        end
    end)
))

local function read_alarms(file)
    local rv = { }
    local date = nil
    for line in io.lines(file) do
        line = line:gsub("\\n", "\n")
        if not date then
            date = line
        else
            rv[date] = line
            date = nil
        end
    end
    return rv
end

local function update (trigger_alarms)
    local date
    if fulldate then
        if type(settings.longtimeformat) == "string" then
            date = os.date(settings.longtimeformat)
        elseif type(settings.longtimeformat) == "function" then
            date = os.date(settings.longtimeformat())
        end
        if not date then
            date = os.date(defaults.longtimeformat)
        end
    else
        if type(settings.shorttimeformat) == "string" then
            date = os.date(settings.shorttimeformat)
        elseif type(settings.shorttimeformat) == "function" then
            date = os.date(settings.shorttimeformat())
        end
        if not date then
            date = os.date(defaults.shorttimeformat)
        end
    end

    if #alarms > 0 then
        date = "<span color='" .. beautiful.fg_focus .. "'>"..date.."</span>"
        widget.bg = beautiful.bg_focus
    else
        widget.bg = beautiful.bg_normal
    end

    widget.text = "<span color=\"#009000\">⚙</span> " .. date

    if trigger_alarms then
        local data = read_alarms(alarmfile)
        local currentdate = os.date("%a-%d-%m-%Y:%H:%M")
        for date, message in pairs(data) do
            if currentdate:match(date) then
                print("notifying")
                print(date, message)
                naughty.notify({ text = message,
                                 title = date,
                                 screen = capi.screen.count()
                              })
                local add = true
                for _, v in pairs(alarms) do
                    if v[1] == date and v[2] == message then
                        add = false
                        break
                    end
                end
                if add then table.insert(alarms, { date, message }) end
            end
        end
        update(false)
    end
end

widget.mouse_enter = function ()
    fulldate = true
    update(false)
end

widget.mouse_leave = function ()
    fulldate = false
    update(false)
end

function set_editor(e)
    settings.editor = e or defaults.editor
end

function set_longformat(strOrFn)
    settings.longtimeformat = strOrFn or defaults.longtimeformat
    update(false)
end

function set_shortformat(strOrFn)
    settings.shorttimeformat = strOrFn or defaults.shorttimeformat
    update(false)
end

setmetatable(_M, { __call = function () 
    update(true)
    awful.hooks.timer.register(60, function() update(true) end)

    menu = awful.menu.new({
        id = "clock",
        items = {
            { "edit todo", function () edit(os.getenv("HOME") .. "/todo") end },
            { "edit alarms", function () edit(alarmfile) end }
        }
    })

    return widget
end })
