# Weather Widget

Displays weather information from [Dark Sky](https://darksky.net)

# Usage

```lua
local weather = require 'obvious.weather'

-- If you put your configuration under version control, I recommend putting
-- this part in a separate, unversioned file
weather.set_api_key(API_KEY) -- Get this from Dark Sky; don't share it with anyone!
weather.set_latitude(lat)
weather.set_longitude(lat)
weather.set_metric(is_metric) -- optional; defaults to true

widget_box:add(weather())
```

# Nice to Have Features

  * Be able to update your location without writing Lua (by hand, or ask a service)
  * Details view popup when you click on the widget (perhaps with hourly/daily) forecast
  * Phases of the moon
  * Custom icons rather than just Unicode glyphs
