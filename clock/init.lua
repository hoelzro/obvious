--------------------------------
-- Author: Gregor Best        --
-- Copyright 2009 Gregor Best --
--------------------------------

local os_time  = os.time
local os_date  = os.date
local tostring = tostring

local pairs = pairs
local print = print
local setmetatable = setmetatable
local tonumber = tonumber
local type = type
local os = {
  date = os.date,
  getenv = os.getenv
}
local io = {
  lines = io.lines,
  popen = io.popen,
}
local string = {
  match = string.match
}
local table = {
  insert = table.insert
}
local capi = {
  mouse = mouse,
  screen = screen
}
local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local naughty = require("naughty")
local lib = {
  hooks = require("obvious.lib.hooks"),
  markup = require("obvious.lib.markup")
}

local clock = {}

local initialized = false
local defaults = {
  shorttimeformat = "%T",
  longtimeformat  = "%T %D",
  editor          = nil,
  shorttimer      = 60,
  longtimer       = 120,
  scrolling       = false,
  scrolltimeout   = 10,
}
local settings = setmetatable({}, { __index = defaults })

local menu

local function edit(file)
  if not settings.editor then
    naughty.notify({ text="Obvious Clock: You need to configure your" ..
               " editor. See readme.",
            timeout=0 })
  else
    awful.util.spawn(settings.editor .. " " .. file)
  end
end

local function pread(cmd)
  local pipe = io.popen(cmd)
  if not pipe then
    return ''
  end
  local results = pipe:read '*a'
  pipe:close()
  return results
end

-- non BSD-like `cal` for -h return help
local function is_bsd()
  return not pread('cal -h'):find('help')
end

local show_calendar
do
  local cal_notification

  function show_calendar(year, month)
    local cmd = 'cal'
    if is_bsd() then
      cmd = 'cal -h'
    end
    cmd = cmd .. ' ' .. tostring(month) .. ' ' .. tostring(year)

    local notify_args = {
      text = lib.markup.font("monospace",
      pread(cmd):
      gsub("([^0-9])(" .. tonumber(os.date("%d")) .. ")([^0-9])",
      "%1<span foreground=\"#FF0000\">%2</span>%3"):gsub("\n+$", "")),
      screen = capi.mouse.screen
    }

    if cal_notification and cal_notification.box.visible then
      notify_args.replaces_id = cal_notification.id
    end

    cal_notification = naughty.notify(notify_args)
  end
end

local alarmfile = awful.util.getdir("config").."/alarms"

local fulldate = false
local alarms = { }

local widget = wibox.widget.textbox()

local last_scroll_time = 0
local displayyear      = 0
local displaymonth     = 0

widget:buttons(awful.util.table.join(
  awful.button({ }, 3, function ()
    menu:toggle()
  end),
  awful.button({}, 4, function()
    displaymonth = displaymonth + 1

    if displaymonth == 13 then
      displaymonth = 1
      displayyear = displayyear + 1
    end

    show_calendar(displayyear, displaymonth)
    last_scroll_time = os_time()
  end),
  awful.button({}, 5, function()
    displaymonth = displaymonth - 1

    if displaymonth == 0 then
      displaymonth = 12
      displayyear = displayyear - 1
    end

    show_calendar(displayyear, displaymonth)
    last_scroll_time = os_time()
  end),
  awful.button({ }, 1, function ()
    if #alarms > 0 then
      for _, v in pairs(alarms) do
        naughty.notify({
          text = v[2],
          title = v[1],
          screen = capi.mouse.screen
        })
      end
      alarms = { }
      widget.bg = beautiful.bg_normal
    else
      if not settings.scrolling or os_time() - settings.scrolltimeout > last_scroll_time then
        local date_info = os_date '*t'
        displayyear     = date_info.year
        displaymonth    = date_info.month
      end

      show_calendar(displayyear, displaymonth)
      last_scroll_time = os_time()
    end
  end)
))

local function read_alarms(file)
  local rv = { }
  local date = nil

  if not awful.util.file_readable(file) then
    return { }
  end

  for line in io.lines(file) do
    line = line:gsub("\\n", "\n")
    if not date then
      date = line
    else
      rv[date] = line
      date = nil
    end
  end
  return rv
end

local function update (trigger_alarms)
  if trigger_alarms == nil then
    trigger_alarms = true
  end
  local date
  if fulldate then
    if type(settings.longtimeformat) == "string" then
      date = os.date(settings.longtimeformat)
    elseif type(settings.longtimeformat) == "function" then
      date = os.date(settings.longtimeformat())
    end
    if not date then
      date = os.date(defaults.longtimeformat)
    end
  else
    if type(settings.shorttimeformat) == "string" then
      date = os.date(settings.shorttimeformat)
    elseif type(settings.shorttimeformat) == "function" then
      date = os.date(settings.shorttimeformat())
    end
    if not date then
      date = os.date(defaults.shorttimeformat)
    end
  end

  if #alarms > 0 then
    date = lib.markup.fg.color(beautiful.fg_focus, date)
    widget.bg = beautiful.bg_focus
  else
    widget.bg = beautiful.bg_normal
  end

  widget:set_markup(date)

  if trigger_alarms then
    local data = read_alarms(alarmfile)
    local currentdate = os.date("%a-%d-%m-%Y:%H:%M")
    for date, message in pairs(data) do
      if currentdate:match(date) then
        naughty.notify({
          text = message,
          title = currentdate,
          screen = capi.screen.count()
        })
        local add = true
        for _, v in pairs(alarms) do
          if v[1] == date and v[2] == message then
            add = false
            break
          end
        end
        if add then table.insert(alarms, { currentdate, message }) end
      end
    end
    update(false)
  end
end

widget:connect_signal("mouse::enter", function ()
  fulldate = true
  update(false)
end)

widget:connect_signal("mouse::leave", function ()
  fulldate = false
  update(false)
end)

function clock.set_editor(e)
  settings.editor = e or defaults.editor
end

function clock.set_longformat(strOrFn)
  settings.longtimeformat = strOrFn or defaults.longtimeformat
  update(false)
end

function clock.set_shortformat(strOrFn)
  settings.shorttimeformat = strOrFn or defaults.shorttimeformat
  update(false)
end

function clock.set_shorttimer(delay)
  settings.shorttimer = delay or defaults.shorttimer
end

function clock.set_longtimer(delay)
  settings.longtimer = delay or defaults.longtimer
end

function clock.set_scrolling(active)
  settings.scrolling = active
end

function clock.set_scrolltimeout(timeout)
  settings.scrolltimeout = timeout
end

return setmetatable(clock, { __call = function ()
  update()
  if not initialized then
    lib.hooks.timer.register(settings.shorttimer, settings.longtimer, update)
    lib.hooks.timer.start(update)

    menu = awful.menu.new({
      id = "clock",
      items = {
        { "Edit Todo", function () edit(os.getenv("HOME") .. "/todo") end },
        { "Edit Alarms", function () edit(alarmfile) end }
      }
    })

    initialized = true
  end

  return widget
end })

-- vim:ft=lua:ts=2:sw=2:sts=2:tw=80:et
