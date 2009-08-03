-----------------------------------
-- Author: Uli Schlachter        --
-- Copyright 2009 Uli Schlachter --
-----------------------------------

local setmetatable = setmetatable
local lib = require("obvious.lib")

module("obvious.wlan.bar")

device = "wlan0"
widget = false

local function update()
    local link = lib.wlan(device)
    widget:set_value(link / 100)
end

function set_device(dev)
    device = dev
    if widget then update() end
end

local function get(layout)
    if not widget then
        -- We must wait until now or beautiful isn't initialized yet
        widget = lib.widgets.progressbar(layout)
        update()
        lib.hooks.timer.register(10, 60, update)
        lib.hooks.timer.start(update)
    end
    return widget
end

setmetatable(_M, { __call = function (_, ...) return get(...) end })
