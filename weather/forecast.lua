local json   = require 'json'
local http_request = require 'http.request'

local function get(api_key, latitude, longitude, units)
  local body = {}
  local url = string.format('https://api.darksky.net/forecast/%s/%s,%s?units=%s',
    api_key,
    latitude,
    longitude,
    units)
  local headers, stream = assert(http_request.new_from_uri(url):go(10))
  local body = assert(stream:get_body_as_string())

  return json.decode(body)
end

return { get = get }
