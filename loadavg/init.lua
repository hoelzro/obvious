<<<<<<< HEAD
-----------------------------------
-- Author: Marco Candrian        --
-- Copyright 2010 Marco Candrian --
-----------------------------------
=======
------------------------------------
-- Author: Marco Candrian        --
-- Copyright 2009 Marco Candrian --
------------------------------------
>>>>>>> 566d98949a7021f0e09e3937049edb7a0f5bd573

local io = io
local pairs = pairs
local print = print
local setmetatable = setmetatable
local tonumber = tonumber
local type = type
local os = {
    date = os.date,
    getenv = os.getenv
}
local capi = {
    widget = widget,
    mouse = mouse,
    screen = screen
}
local awful = require("awful")
local beautiful = require("beautiful")
local naughty = require("naughty")
local lib = {
    hooks = require("obvious.lib.hooks"),
    markup = require("obvious.lib.markup")
}

module("obvious.loadavg")

local initialized = false
local defaults = { }
<<<<<<< HEAD
defaults.shorttimer =  5 -- loadavg won't change faster anyway (it seems)
=======
defaults.shorttimer =  5 -- loadavg won't change faster it seems anyway
>>>>>>> 566d98949a7021f0e09e3937049edb7a0f5bd573
defaults.longtimer =  60
defaults.prefix = ""
defaults.suffix = ""
defaults.command = "xterm -e top"
local settings = { }
for key, value in pairs(defaults) do
    settings[key] = value
end

local widget = capi.widget({
        type = "textbox",
        name = "loadavg",
        align = "right"
    })

widget:buttons(awful.util.table.join(
    awful.button({ }, 1, function ()
        awful.util.spawn(settings.command)
    end)
))

<<<<<<< HEAD
=======

>>>>>>> 566d98949a7021f0e09e3937049edb7a0f5bd573
-- update interval
function set_shorttimer(e)
    settings.shorttimer = e or defaults.shorttimer
end
<<<<<<< HEAD

=======
>>>>>>> 566d98949a7021f0e09e3937049edb7a0f5bd573
-- command to issue on Button1 click
function set_command(e)
    settings.command = e or defaults.command
end

-- prefix to the data - e.g. using pango 'text markup language'
function set_prefix(e)
    settings.prefix = e or defaults.prefix
end

-- suffix to the data
function set_suffix(e)
    settings.suffix = e or defaults.suffix
end

local function update ()
    local f = io.open("/proc/loadavg")

    local loadavg
    loadavg = f:read(14)
    f:close()
    widget.text = settings.prefix .. loadavg .. settings.suffix
end

setmetatable(_M, { __call = function () 
    update()
    if not initialized then
        lib.hooks.timer.register(settings.shorttimer, settings.longtimer, update)
        lib.hooks.timer.start(update)

        initialized = true
    end

    return widget
end })
