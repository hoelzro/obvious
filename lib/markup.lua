-----------------------------------
-- Author: Uli Schlachter        --
-- Copyright 2009 Uli Schlachter --
-- Copyright 2009 Majic          --
-----------------------------------

local beautiful = require("beautiful")
local tostring = tostring

local markup = {
   fg = {},
   bg = {},
}

--[[

-- Little map of how I
-- organized this for usage.

  +-- markup
  |
  |`-- bold()        Set bold.
  |`-- italic()      Set italicized text.
  |`-- strike()      Set strikethrough text.
  |`-- underline()   Set underlined text.
  |`-- big()         Set bigger text.
  |`-- small()       Set smaller text.
  |`-- font()        Set the font of the text.
  |
  |`--+ bg
  |   |
  |   |`-- color()   Set background color.
  |   |`-- focus()   Set focus  background color.
  |   |`-- normal()  Set normal background color.
  |    `-- urgent()  Set urgent background color.
  |
  |`--+ fg
  |   |
  |   |`-- color()   Set foreground color.
  |   |`-- focus()   Set focus  foreground color.
  |   |`-- normal()  Set normal foreground color.
  |    `-- urgent()  Set urgent foreground color.
  |
  |`-- focus()       Set both foreground and background focus  colors.
  |`-- normal()      Set both foreground and background normal colors.
   `-- urgent()      Set both foreground and background urgent colors.

]]

-- Basic stuff...
function markup.bold(text)      return '<b>'     .. tostring(text) .. '</b>'     end
function markup.italic(text)    return '<i>'     .. tostring(text) .. '</i>'     end
function markup.strike(text)    return '<s>'     .. tostring(text) .. '</s>'     end
function markup.underline(text) return '<u>'     .. tostring(text) .. '</u>'     end
function markup.big(text)       return '<big>'   .. tostring(text) .. '</big>'   end
function markup.small(text)     return '<small>' .. tostring(text) .. '</small>' end

function markup.font(font, text)
  return '<span font_desc="'  .. tostring(font)  .. '">' .. tostring(text) ..'</span>'
end

-- Set the foreground.
function markup.fg.color(color, text)
  return '<span foreground="' .. tostring(color) .. '">' .. tostring(text) .. '</span>'
end

-- Set the background.
function markup.bg.color(color, text)
  return '<span background="' .. tostring(color) .. '">' .. tostring(text) .. '</span>'
end

-- Context: focus
function markup.fg.focus(text)  return markup.fg.color(beautiful.fg_focus, text)  end
function markup.bg.focus(text)  return markup.bg.color(beautiful.bg_focus, text)  end
function    markup.focus(text)  return markup.bg.focus(markup.fg.focus(text))     end

-- Context: normal
function markup.fg.normal(text) return markup.fg.color(beautiful.fg_normal, text) end
function markup.bg.normal(text) return markup.bg.color(beautiful.bg_normal, text) end
function    markup.normal(text) return markup.bg.normal(markup.fg.normal(text))   end

-- Context: urgent
function markup.fg.urgent(text) return markup.fg.color(beautiful.fg_urgent, text) end
function markup.bg.urgent(text) return markup.bg.color(beautiful.bg_urgent, text) end
function    markup.urgent(text) return markup.bg.urgent(markup.fg.urgent(text))   end

return markup

-- vim:ft=lua:ts=2:sw=2:sts=2:tw=80:et
