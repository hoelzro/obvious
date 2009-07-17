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
    ["charging"] = "▲",
    ["unknown"] = "⌁"
}

function get_data()
    local rv = { }
    local fd = io.popen("acpi -b")
    if not fd then return end

    local data = fd:read("*all"):match("Battery [0-9] *: ([^\n]*)")
    if not data then return end

    rv.state = data:match("([%a]*),.*"):lower()
    rv.charge = tonumber(data:match(".*, ([%d]?[%d]?[%d]%.?[%d]?[%d]?)%%"))
    rv.time = data:match(".*, ([%d]?[%d]?:?[%d][%d]:[%d][%d])")

    return rv
end

local function update()
    local battery_status = ""

    local bat = get_data()
    if not bat then
        widget.text = "no data"
        return
    end
    local color = "#900000"
    if bat.charge > 35 and bat.charge < 60 then
        color = "#909000"
    elseif bat.charge >= 40 then
        color = "#009000"
    end

    local state = bat.state
    if not status[state] then
        state = "unknown"
    end
    state = status[state]

    battery_status = "<span color=\"" .. color .. "\">"..state.."</span> " .. awful.util.escape(tostring(bat.charge)) .. "%"

    if bat.time then
        battery_status = battery_status .. " " .. awful.util.escape(bat.time)
    end

    widget.text = battery_status
end

local function detail ()
    local fd = io.popen("acpi -bta")
    local d = fd:read("*all"):gsub("(\n$", "")
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
