local json   = require 'dkjson'
local http_request = require 'http.request'

local function get(api_key, latitude, longitude, units)
  local body = {}
  local url = string.format('https://api.darksky.net/forecast/%s/%s,%s?units=%s',
    api_key,
    latitude,
    longitude,
    units)

  local headers, stream = http_request.new_from_uri(url):go(10)
  if not headers then
    return nil, stream
  end

  local body, err = stream:get_body_as_string()
  if not body then
    return nil, err
  end

  local res, _, err = json.decode(body)
  if not res then
    return nil, err
  end

  return res
end

return { get = get }
