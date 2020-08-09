--------------------------------------------
-- Author: Gregor Best                    --
-- Copyright 2009, 2010, 2011 Gregor Best --
--------------------------------------------

local tonumber = tonumber
local pcall = pcall
local io = {
  open = io.open,
  popen = io.popen
}
local math = {
  floor = math.floor
}

local os = "unknown"

local first_wlan = nil

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

local function get_info_openbsd(device)
  local repl = {
    ["^\tieee80211: "] = "802.11:\t",
    ["^\tinet(.?) "] = "inet%1:\t",
    ["^\tmedia: "] = "media:\t"
  }
  local fh = io.popen("ifconfig " .. device)
  local rv = ""

  function string:multimatch(patterns)
    for _, v in ipairs(patterns) do
      if self:match(v) then
        return true
      end
    end
    return false
  end

  for line in fh:lines() do
    for k, v in pairs(repl) do
      line = line:gsub(k, v)
    end
    if line:multimatch({ "^media", "^802%.11", "^inet" }) then
      rv = rv .. "\n" .. line
    end
  end
  fh:close()

  return rv:gsub("^\n", "")
end

local function get_data_openbsd(device)
  local link = 0
  local fd = io.popen("/sbin/ifconfig " .. device)
  if not fd then return 0 end

  for line in fd:lines() do
    if line:match("ieee80211: ") then
      link = tonumber(line:match("(%d?%d?%d)dB"))
      break
    end
  end
  fd:close()

  if not link then
    return 0
  end
  return link
end

local function find_first_wlan_openbsd()
  local last_device = nil
  local wlan_device = nil

  local fd = io.popen("/sbin/ifconfig")
  if not fd then
    return
  end

  for line in fd:lines() do
    local m = line:match("^(%w+): ")
    if m then
      last_device = m
    else
      m = line:match("%s+ieee80211: ")
      if m and last_device then
        wlan_device = last_device
        break
      end
    end
  end

  fd:close()

  return wlan_device
end

local function get_data_linux(device)
  local link = 0
  local fd = io.open("/proc/net/wireless")
  if not fd then return end

  for line in fd:lines() do
    if line:match("^%s*"..device) then
      link = tonumber(line:match("   (%d?%d?%d)"))
      break
    end
  end
  fd:close()

  fd = io.popen("/sbin/iwconfig " .. device)
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

local function find_first_wlan_linux()
  local device = nil
  local fd = io.open("/proc/net/wireless")
  if not fd then return end

  for line in fd:lines() do
    local m = line:match("^%s*(%w+): ")
    if m then
      device = m
      break
    end
  end
  fd:close()

  return device
end

local function find_first_wlan()
  if first_wlan then
    return first_wlan
  end

  determine_os()
  if os == "OpenBSD" then
    first_wlan = find_first_wlan_openbsd()
  else
    first_wlan = find_first_wlan_linux()
  end

  return first_wlan
end

local function get_data(device)
  determine_os()
  if os == "OpenBSD" then
    return get_data_openbsd(device)
  end
  return get_data_linux(device)
end

local function get_info(device)
  determine_os()
  if os == "OpenBSD" then
    return get_info_openbsd(device)
  end
  return ""
end

return setmetatable({
  find_first_wlan = first_wlan,
}, { __call = function (_, ...) return get_data(...) end })

-- vim:ft=lua:ts=2:sw=2:sts=2:tw=80:et
