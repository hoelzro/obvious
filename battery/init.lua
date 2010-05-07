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
local os = {
    execute = os.execute
}
local capi = {
    widget = widget,
    mouse = mouse
}

local naughty = require("naughty")
local awful = require("awful")
local lib = {
    hooks = require("obvious.lib.hooks"),
    markup = require("obvious.lib.markup")
}

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

local backend = "acpi"
get_data = nil

local function init()
    local rv = os.execute("acpitool")
    if rv == 0 then
        backend = "acpitool"
        return
    end

    rv = os.execute("acpi")
    if rv == 0 then
        backend = "acpi"
        return
    end

    rv = os.execute("apm")
    if rv == 0 then
        backend = "apm"
        return
    end

    backend = "none"
end

function get_data()
    if backend == "acpi" or backend == "acpitool" then
        local rv = { }
        local fd = io.popen(backend .. " -b")
        if not fd then return end

        local line = fd:read("*l")
        while line do
            local data = line:match("Battery #?[0-9] *: ([^\n]*)")

            rv.state = data:match("([%a]*),.*"):lower()
            rv.charge = tonumber(data:match(".*, ([%d]?[%d]?[%d]%.?[%d]?[%d]?)%%"))
            rv.time = data:match(".*, ([%d]?[%d]?:?[%d][%d]:[%d][%d])")

            if not rv.state:match("unknown") then break end
            line = fd:read("*l")
        end

        fd:close()

        return rv
    elseif backend == "apm" then
        local rv = { }
        local fd = io.popen("apm")
        if not fd then return end

        local data = fd:read("*all")
        if not data then return end

        rv.state  = data:match("battery ([a-z]+):")
        rv.charge = tonumber(data:match(".*, .*: (%d?%d?%d)%%"))
        rv.time = data:match("%((.*)%)$")

        return rv
    end
    local rv = { }
    rv.state = "unknown"
    rv.charge = 0
    rv.time = "00:00"
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
    if not bat.charge then
        widget.text = lib.markup.fg.color("#009000", status.charged) .. " A/C"
        return
    elseif bat.charge > 35 and bat.charge < 60 then
        color = "#909000"
    elseif bat.charge >= 40 then
        color = "#009000"
    end

    local state = bat.state
    if not status[state] then
        state = "unknown"
    end
    state = status[state]

    battery_status = lib.markup.fg.color(color, state) .. " " .. awful.util.escape(tostring(bat.charge)) .. "%"

    if bat.time then
        battery_status = battery_status .. " " .. awful.util.escape(bat.time)
    end

    widget.text = battery_status
end

local function detail ()
    local fd = nil
    if backend == "acpi" then
        fd = io.popen("acpi -bta")
    elseif backend == "acpitool" then
        fd = io.popen("acpitool")
    elseif backend == "apm" then
        fd = io.popen("apm")
    else
        naughty.notify({ text = "unknown backend: " .. backend })
    end
    local d = fd:read("*all"):gsub("\n+$", "")
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
init()
update()
lib.hooks.timer.register(60, 300, update)
lib.hooks.timer.start(update)

setmetatable(_M, { __call = function () return widget end })
