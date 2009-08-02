--------------------------------
-- Author: Gregor Best        --
-- Copyright 2009 Gregor Best --
--------------------------------

local setmetatable = setmetatable
local tonumber = tonumber

local io = {
    open = io.open
}
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

function get_data()
    local rv = { }

    local fd = io.open("/proc/net/wireless")
    if not fd then return end

    for line in fd:lines() do
        if line:match("^ "..device) then
            rv.link = tonumber(line:match("   (%d?%d?%d)"))
            break
        end
    end
    fd:close()
    if not rv.link then return end

    return rv
end

local function update()
    local status = get_data()

    local color = "#009000"
    if status.link < 50 and status.link > 10 then
        color = "#909000"
    elseif status.link <= 10 then
        color = "#900000"
    end
    widget.text = lib.util.colour(color,"☢") .. string.format(" %03d%%", status.link)
end
update()
lib.hooks.timer.register(10, 60, update)
lib.hooks.timer.start(update)

function set_device(dev)
    device = dev
    update()
end

setmetatable(_M, { __call = function () return widget end })
