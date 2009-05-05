--------------------------------
-- Author: Gregor Best        --
-- Copyright 2009 Gregor Best --
--------------------------------

local tonumber = tonumber
local tostring = tostring
local setmetatable = setmetatable
local io = {
    popen = io.popen
}
local capi = {
    widget = widget,
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
    ["full"] = "↯",
    ["discharging"] = "▼",
    ["charging"] = "▲"
}

local function update()
    local battery_status = ""
    local fd = io.popen("acpi -V")
    if not fd then 
        widget.text = "acpitool failed"
        return
    end

    local data = fd:read("*all"):match("Battery [0-9] *: ([^\n]*)")
    fd:close()
    if not data then
        widget.text = "no data"
        return
    end
    local state = data:match("([%a]*),.*")
    local charge = tonumber(data:match(".*, ([%d]?[%d]?[%d]%.?[%d]?[%d]?)%%"))
    local time = data:match(".*, ([%d]?[%d]?:?[%d][%d]:[%d][%d])")
    
    local color = "#900000"
    if charge > 35 and charge < 60 then
        color = "#909000"
    elseif charge >= 40 then
        color = "#009000"
    end
    battery_status = "<span color=\"" .. color .. "\">"..status[state:lower()].."</span> " .. awful.util.escape(tostring(charge)) .. "%"

    if time then
        battery_status = battery_status .. " " .. awful.util.escape(time)
    end

    widget.text = battery_status
end

local function detail ()
    local fd = io.popen("acpi -V")
    local d = fd:read("*all")
    fd:close()
    naughty.notify({
        text = d,
        screen = capi.mouse.screen
    })
    update()
end

widget:buttons(awful.util.table.join(
    awful.button({ }, 1, detail)
))
update()
awful.hooks.timer.register(60, update)

setmetatable(_M, { __call = function () return widget end })
