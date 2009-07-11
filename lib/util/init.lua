------------------------------------------
-- Author: Andrei "Garoth" Thorp        --
-- Copyright 2009 Andrei "Garoth" Thorp --
------------------------------------------
module("obvious.lib.util")

-- Set Foreground colour of text
-- @param colour The colour you want to set the text to
-- @param text The text you want to colour
-- @return The coloured string
function colour(colour, text)
        return '<span color="' .. colour .. '">' .. text .. '</span>'
end

-- Make bold text
-- @param text The text you want to make bold
-- @return The bolded text
function bold(text)
        return '<b>' .. text .. '</b>'
end
-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=4:softtabstop=4:encoding=utf-8:textwidth=80
