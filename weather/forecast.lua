local socket = require 'socket'
local http   = require 'socket.http'
local ssl    = require 'ssl'
local ltn12  = require 'ltn12'
local json   = require 'json'

local ssl_methods = { send = true, receive = true }

local function create_ssl_socket()
  local function perform_ssl_connect(self, host, port)
    local ssl_socket
    local ok, err = self._tcp_socket:connect(host, 443) -- XXX hardcoded port =/

    if not ok then
      return nil, err
    end

    ssl_socket, err = ssl.wrap(self._tcp_socket, {
      mode        = 'client',
      protocol    = 'tlsv1',
      cafile      = '/etc/ssl/cert.pem',
      certificate = '/etc/ssl/cert.pem',
      verify      = { 'peer', 'fail_if_no_peer_cert' },
      options     = { 'all', 'no_sslv2', 'no_sslv3' },
    })

    if not ssl_socket then
      return nil, err
    end

    ok, err = ssl_socket:dohandshake()

    if not ok then
      return nil, err
    end

    self._ssl_socket = ssl_socket
    return self
  end

  local function __index(self, key)
    local object = ssl_methods[key] and self._ssl_socket or self._tcp_socket
    local value  = object[key]

    if type(value) == 'function' then
      local orig = value
      value = function(self, ...)
        return orig(object, ...)
      end
    end

    if value ~= nil then
      rawset(self, key, value)
    end

    return value
  end

  local tcp_socket, err = socket.tcp()
  if not tcp_socket then
    return nil, err
  end

  return setmetatable({
    connect = perform_ssl_connect,
    _tcp_socket = tcp_socket,
    _ssl_socket = false,
  }, { __index = __index, __newindex = error })
end

local function get(api_key, latitude, longitude, units)
  local body = {}
  local url = string.format('https://api.darksky.net/forecast/%s/%s,%s?units=%s',
    api_key,
    latitude,
    longitude,
    units)
  local _, status, headers, status_line = assert(http.request {
    url = url,
    sink = ltn12.sink.table(body),
    create = create_ssl_socket,
  })
  assert(status == 200, status_line)
  return json.decode(table.concat(body))
end

return { get = get }
