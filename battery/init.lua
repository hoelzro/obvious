--------------------------------
-- Author: Gregor Best        --
-- Copyright 2009 Gregor Best --
--------------------------------

local tonumber = tonumber
local setmetatable = setmetatable
local io = {
    popen = io.popen
}
local capi = {
    widget = widget,
    button = button,
    mouse = mouse
}

local naughty = require("naughty")
local awful = require("awful")

module("obvious.battery")

widget = capi.widget({
    type = "textbox",
    name = "tb_battery",
    align = "right"
})
status = {
    ["charged"] = "↯",
    ["discharging"] = "▼",
    ["charging"] = "▲"
}

local function update()
    local battery_status = ""
    local fd = io.popen("acpitool")
    if not fd then 
        widget.text = "acpitool failed"
        return
    end

    local data = fd:read("*all"):match("Battery #1 *: ([^\n]*)")
    fd:close()
    local state = data:match("([%a]*),.*")
    local charge = tonumber(data:match(".*, ([%d]?[%d]?[%d]%.[%d]?[%d]?)"))
    local time = data:match(".*, ([%d][%d]:[%d][%d])")
    
    local color = "#FF0000"
    if charge > 35 and charge < 60 then
        color = "#FFFF00"
    elseif charge >= 40 then
        color = "#00FF00"
    end
    battery_status = "<span color=\"" .. color .. "\">"..status[state].."</span> " .. charge .. "%"

    if time then
        battery_status = battery_status .. " " .. time
    end

    widget.text = battery_status
end

local function detail ()
    local fd = io.popen("acpitool")
    local d = fd:read("*all")
    fd:close()
    naughty.notify({
        text = d,
        screen = capi.mouse.screen
    })
end

widget:buttons({ 
    capi.button({ }, 1, detail)
}) 
update()
awful.hooks.timer.register(60, update)

setmetatable(_M, { __call = function () return widget end })
