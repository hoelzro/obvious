Battery widget
==============

This widget is a battery monitor. It gets its information from `upower`, `acpi`,
`acpitool` or from `apm`, to be as uniquely usable as possible. With `apm` as the
backend, some information might not be available, such as whether the battery is
currently charged or whether it is discharging. Charge is displayed with either
backends.
If you click on the widget, additional information is displayed.

To use it, include it into your rc.lua by inserting this line:

```lua
    local battery = require("obvious.battery")
```

into the top of your rc.lua. Then add the widget to your wibox. It's called

```lua
    battery()
```

If you want to use the data gathered by this widget to create your own, use the
function `battery.get_data()`. It returns nil on failure and it returns
a table on success. If you have multiple batteries, only information for the
first is returned. The table has the following fields:

* `status`: a string which describes the batteries' state as one element of the
  set `["charged", "full", "discharging", "charging"]` (most likely, some
  acpi implementations might output different values)
* `charge`: a number representing the current battery charge as a number between
  0 and 100
* `time`: the time left to full charge or complete discharge, in minutes

To set your preferred backend:

    local battery = require("obvious.battery")
    battery.preferred_backend = 'apm'
    battery()
