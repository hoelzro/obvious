--------------------------------
-- Author: Gregor Best        --
-- Copyright 2009 Gregor Best --
--------------------------------

local tonumber = tonumber
local setmetatable = setmetatable
local io = {
    open = io.open,
    popen = io.popen
}
local math = {
    floor = math.floor
}

module("obvious.lib.wlan")

local function get_data(device)
    local link = 0
    local fd = io.open("/proc/net/wireless")
    if not fd then return end

    for line in fd:lines() do
        if line:match("^ "..device) then
            link = tonumber(line:match("   (%d?%d?%d)"))
            break
        end
    end
    fd:close()

    fd = io.popen("iwconfig " .. device)
    if fd then
        local scale = 100
        for line in fd:lines() do
            if line:match("Link Quality=") then
                scale = tonumber(line:match("=%d+/(%d+)"))
            end
        end
        link = math.floor((link / scale) * 100)
    end
    return link
end

setmetatable(_M, { __call = function (_, ...) return get_data(...) end })
