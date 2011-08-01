--------------------------------
-- Author: Gregor Best        --
-- Copyright 2009 Gregor Best --
--------------------------------

local tonumber = tonumber
local pcall = pcall
local setmetatable = setmetatable
local io = {
    open = io.open,
    popen = io.popen
}
local math = {
    floor = math.floor
}

module("obvious.lib.wlan")

local os = "unknown"

local function determine_os ()
    if os ~= "unknown" then
        return
    end
    local fh = io.popen("uname")
    local ok = nil
    ok, os = pcall(function () return fh:read():sub(1, -1) end)
    fh:close()
    if not ok then
    	os = "unknown"
    end
    return os
end

local function get_data_openbsd(device)
    local link = 0
    local fd = io.popen("ifconfig " .. device)
    if not fd then return end

    for line in fd:lines() do
        if line:match("ieee80211: ") then
            link = tonumber(line:match("(%d?%d?%d)dB"))
            break
        end
    end
    fd:close()

    if not link then
        return
    end
    return link
end

local function get_data_linux(device)
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

local function get_data(device)
    determine_os()
    if os == "OpenBSD" then
        return get_data_openbsd(device)
    end
    return get_data_linux(device)
end

setmetatable(_M, { __call = function (_, ...) return get_data(...) end })
