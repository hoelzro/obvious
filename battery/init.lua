--------------------------------------------
-- Author: Gregor Best                    --
-- Copyright 2009, 2010, 2011 Gregor Best --
--------------------------------------------

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
    mouse = mouse
}
local table = {
    remove = table.remove
}

local naughty = require("naughty")
local awful = require("awful")
local wibox = require("wibox")
local lib = {
    hooks = require("obvious.lib.hooks"),
    markup = require("obvious.lib.markup")
}

module("obvious.battery")

local widget = wibox.widget.textbox()
local status = {
    ["charged"] = "↯",
    ["full"] = "↯",
    ["high"] = "↯",
    ["discharging"] = "▼",
    ["not connected"] = "▼",
    ["charging"] = "▲",
    ["unknown"] = "⌁"
}

local backend = function() return nil end
local backend_detail = function () return "unknown backend" end

local backends = {
    ["acpiconf"] = function ()
        local rv = {}
        local fd = io.popen("acpiconf -i0")
        for l in fd:lines() do
            if l:match("^Remaining capacity") then
                rv.charge = tonumber(l:match("\t(%d?%d?%d)"))
            elseif l:match("^Remaining time") then
                rv.time = l:match("\t(%S+)")
                if rv.time == "unknown" then
                    rv.time = ""
                end
            elseif l:match("^State") then
                rv.state = l:match("\t(%S+)")
            end
        end
        fd:close()
        return rv
    end,
    ["acpi"] = function (be)
        be = be or "acpi"
        local rv = {}
        local fd = io.popen(be .. " -b")
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
    end,
    ["acpitool"] = function()
        return backends["acpi"]("acpitool")
    end,
    ["apm"] = function ()
        local rv = {}
        local fd = io.popen("apm")
        if not fd then return end

        local data = fd:read("*all")
        if not data then return end

        rv.state  = data:match("battery ([a-z]+):")
        rv.charge = tonumber(data:match(".*, .*: (%d?%d?%d)%%"))
        rv.time = data:match("%((.*)%)$")

        fd:close()

        return rv
    end,
    ["apm-obsd"] = function ()
        local rv = {}
        local fd = io.popen("apm -l -b -m")
        if not fd then return end
        local fields = { "state", "charge", "time" }
        local states = {
            ["0"] = "high",
            ["1"] = "low",
            ["2"] = "critical",
            ["3"] = "charging",
            ["4"] = "absent",
            ["255"] = "unknown"
        }
        for line in fd:lines() do
            rv[table.remove(fields, 1)] = line
        end
        fd:close()

        rv.state = states[rv.state]
        if not rv.state then
            rv.state = "unknown"
        end
        rv.charge = tonumber(rv.charge)
        return rv
    end
}

local backends_detail = {
    ["acpiconf"] = function ()
        local str = ""
        local fd = io.popen("sysctl hw.acpi.thermal")
        for l in fd:lines() do
            if l:match("tz%d%.temperature") then
                str = str .. "\n" .. l
            end
        end
        fd:close()
        return str:gsub("^\n", "")
    end,
    ["common"] = function (be)
        local fd = io.popen(be)
        local d = fd:read("*all"):gsub("\n+$", "")
        fd:close()
        return d
    end
}

local function init()
    local rv = os.execute("acpiconf")
    if rv == 0 then
        backend = backends["acpiconf"]
        backend_detail = backends_detail["acpiconf"]
        return
    end

    local rv = os.execute("acpitool")
    if rv == 0 then
        backend = backends["acpitool"]
        backend_detail = function () return backends_detail["common"]("acpitool") end
        return
    end

    rv = os.execute("acpi")
    if rv == 0 then
        backend = backends["acpi"]
        backend_detail = function () return backends_detail["common"]("acpi") end
        return
    end

    rv = os.execute("apm")
    if rv == 0 then
        fh = io.popen("uname")
        if fh:read("*all") == "OpenBSD\n" then
            backend = backends["apm-obsd"]
        else
            backend = backends["apm"]
        end
        fh:close()
        backend_detail = function () return backends_detail["common"]("apm") end
        return
    end
end

function get_data()
    local rv = backend()
    rv.state = rv.state or "unknown"
    rv.time = rv.time or "00:00"
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

    widget:set_markup(battery_status)
end

local function detail ()
    naughty.notify({
        text = backend_detail(),
        screen = capi.mouse.screen
    })
    update()
end

widget:buttons(awful.util.table.join(
    awful.button({ }, 1, detail)
))
lib.hooks.timer.register(60, 300, update)

setmetatable(_M, { __call = function ()
    init()
    update()
    lib.hooks.timer.start(update)
    return widget
end })
