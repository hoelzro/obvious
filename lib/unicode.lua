local utf8length
local utf8positions

local has_native, nativelib = pcall(require, 'obvious.lib.unicode.native')

if has_native then
  return nativelib
end

local naughty = require 'naughty'

naughty.notify {
  title   = 'Obvious',
  text    = 'Not using native Unicode library for obvious - it is highly recommended to compile the native library for accuracy',
  timeout = 0,
}

if utf8 then
  utf8length = utf8.len
else
  local sbyte = string.byte

  function utf8positions(s)
    local function iter(s, pos)
      if not pos then
        return 1
      end

      local byte = sbyte(s, pos)

      if byte >= 0xf0 then
        pos = pos + 4
      elseif byte >= 0xe0 then
        pos = pos + 3
      elseif byte >= 0xc0 then
        pos = pos + 2
      else
        pos = pos + 1
      end

      if pos > #s then
        return nil
      end

      return pos
    end

    if s == '' then
      return function() end, s, nil
    else
      return iter, s, nil
    end
  end

  function utf8length(s)
    local count = 0

    for _ in utf8positions(s) do
      count = count + 1
    end

    return count
  end
end

local function utf8sub(s, start, finish)
  local start_byte
  local end_byte = #s

  local charno = 1
  for pos in utf8positions(s) do
    if charno == start then
      start_byte = pos

      if not finish then
        break
      end
    end

    if finish and charno == finish + 1 then
      end_byte = pos - 1
      break
    end

    charno = charno + 1
  end

  return string.sub(s, start_byte, end_byte)
end

return {
  length = utf8length,
  sub    = utf8sub,
}
