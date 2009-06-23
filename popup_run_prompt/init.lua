------------------------------------------
-- Author: Andrei "Garoth" Thorp        --
-- Copyright 2009 Andrei "Garoth" Thorp --
------------------------------------------

local mouse = mouse
local awful = require("awful")
local widget = widget
local screen = screen
local ipairs = ipairs
local pairs = pairs
local io = io
local beautiful = require("beautiful")

module("obvious.popup_run_prompt")

defaults = {}
-- Default is 1 for people without compositing
defaults.opacity = 1.0
defaults.prompt_string = "  Run~  "
-- Whether or not the bar should slide up or just pop up
defaults.slide = false
-- Bar will be percentage of screen width
defaults.width = 0.6
-- Bar will be this high in pixels
defaults.height = 22
defaults.border_width = 1
-- When sliding, it'll move this often (in seconds)
defaults.move_speed = 0.02
-- When sliding, it'll move this many pixels per move
defaults.move_amount = 3

-- Clone the defaults for the used settings
settings = {}
for key, value in pairs(defaults) do
        settings[key] = value
end

runwibox = {}
mypromptbox = {}
inited = false

-- We want to "lazy init" so that in case beautiful inits late or something,
-- this is still likely to work.
function ensure_init()
    if inited then
        return
    end

    inited = true
    for s = 1, screen.count() do
        mypromptbox[s] = widget({
                type = "textbox",
                name = "mypromptbox" .. s,
                align = "left"
        })

        runwibox[s] = awful.wibox({
                position = "float",
                fg = beautiful.fg_normal,
                bg = beautiful.bg_normal,
                border_width = settings.border_width,
                border_color = beautiful.bg_focus,
                screen = s
        })
        set_default(s)
        runwibox[s].opacity = settings.opacity
        runwibox[s].visible = false
        runwibox[s].ontop = true

        -- Widgets for prompt wibox
        runwibox[s].widgets = {
                mypromptbox[s],
        }
    end
end

function set_default(s)
    local s = s or mouse.screen
    runwibox[s]:geometry({
            width = screen[s].geometry.width * settings.width,
            height = settings.height,
            x = screen[s].geometry.x + screen[s].geometry.width *
                ((1 - settings.width) / 2),
            y = screen[s].geometry.y + screen[s].geometry.height -
                settings.height,
    })
end

function show_wibox(s)
    local s = s or mouse.screen

    if settings.slide == true then
        startgeom = runwibox[s]:geometry()
        runwibox[s]:geometry({
            y = screen[s].geometry.y + screen[s].geometry.height,
        })
        runwibox[s].visible = true

        f = function ()
            startgeom = runwibox[s]:geometry()
            runwibox[s]:geometry({
                y = startgeom.y - settings.move_amount,
            })
            if runwibox[s]:geometry().y <= screen[s].geometry.y +
                    screen[s].geometry.height - startgeom.height then
                set_default(mouse.screen)
                awful.hooks.timer.unregister(f)
            end
        end

        awful.hooks.timer.register(settings.move_speed, f)
    else
        set_default(s)
        runwibox[s].visible = true
    end
end

function hide_wibox(s)
    local s = s or mouse.screen

    if settings.slide == true then
        runwibox[s].visible = true
        set_default(s)

        f = function ()
            startgeom = runwibox[s]:geometry()
            runwibox[s]:geometry({
                y = startgeom.y + settings.move_amount,
            })
            if runwibox[s]:geometry().y >= screen[s].geometry.y +
                    screen[s].geometry.height then
                runwibox[s].visible = false
                awful.hooks.timer.unregister(f)
            end
        end

        awful.hooks.timer.register(settings.move_speed, f)
    else
        set_default(s)
        runwibox[s].visible = false
    end
end

function run_prompt_callback()
    hide_wibox(mouse.screen)
end

function run_prompt()
    ensure_init()
    show_wibox(mouse.screen)

    awful.prompt.run({ prompt = settings.prompt_string },
            mypromptbox[mouse.screen],
            awful.util.spawn,
            awful.completion.shell,
            awful.util.getdir("cache") .. "/history",
            100,
            run_prompt_callback
    )
end

-- SETTINGS
function set_opacity(amount)
    settings.opacity = amount or defaults.opacity
    update_settings()
end

function set_prompt_string(string)
    settings.prompt_string = string or defaults.prompt_string
end

function set_slide(tf)
    settings.slide = tf or defaults.slide
end

function set_width(amount)
    settings.width = amount or defaults.width
    update_settings()
end

function set_height(amount)
    settings.height = amount or defaults.height
    update_settings()
end

function set_border_width(amount)
    settings.border_width = amount or defaults.border_width
    update_settings()
end

function set_move_speed(amount)
    settings.move_speed = amount or defaults.move_speed
end

function set_move_amount(amount)
    settings.move_amount = amount or defaults.move_amount
end

function update_settings()
    for s, value in ipairs(runwibox) do
        value.border_width = settings.border_width
        set_default(s)
        runwibox[s].opacity = settings.opacity
    end
end
