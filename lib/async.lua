local table = table

module 'obvious.lib.async'

local function list_iter(t)
   local i = 0
   local n = table.getn(t)
   return function ()
      i = i + 1
      if i <= n then return t[i] end
   end
end

local function find2(iter, callback)
   local item = iter()
   if item then
      item(function(result)
            if result then
               callback(item)
            else
               find2(iter, callback)
            end
      end)
   else
      callback()
   end
end

-- Find the first match that returns true asynchronously
-- @param list An array of functions
-- @param callback The callback
function find(list, callback)
   iter = list_iter(list)
   find2(iter, callback)
end
