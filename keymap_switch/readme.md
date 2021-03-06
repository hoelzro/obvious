Keymap Widget
=============

This widget shows the current keyboard layout.

To add this widget to your configuration, insert

```lua
    local keymap_switch = require("obvious.keymap_switch")
```

into the top of your rc.lua and add `keymap_switch()` to your wibox.

This widget provides some options:
* `keymap_switch.set_layouts(layouts_table)` where `layouts_table` is
  a simple table of input strings to setxkbmap. For example, to allow the
  widget to switch between Qwerty and Dvorak, the call would look like:

```lua
    keymap_switch.set_layouts({ "us", "us(dvorak)" })
```
