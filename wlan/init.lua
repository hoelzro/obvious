--------------------------------
-- Author: Gregor Best        --
-- Copyright 2009 Gregor Best --
--------------------------------

local setmetatable = setmetatable

local string = {
    format = string.format
}
local capi = {
    widget = widget
}

local awful = require("awful")
local lib = require("obvious.lib")

module("obvious.wlan")

widget = capi.widget({
    type = "textbox",
    name = "tb_wlan",
    align = "right"
})
device = "wlan0"

local function update()
    local link = lib.wlan(device)

    local color = "#009000"
    if link < 50 and link > 10 then
        color = "#909000"
    elseif link <= 10 then
        color = "#900000"
    end
    widget.text = lib.util.colour(color,"☢") .. string.format(" %03d%%", link)
end
update()
lib.hooks.timer.register(10, 60, update)
lib.hooks.timer.start(update)

function set_device(dev)
    device = dev
    update()
end

setmetatable(_M, { __call = function () return widget end })
