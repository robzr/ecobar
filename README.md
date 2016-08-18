ecoBar
---
Ecobee BitBar Plugin for monitoring and controlling an Ecobee thermostat.

<img src="https://raw.githubusercontent.com/robzr/ecobar/master/images/screenshot.png" 
  alt="Example output from one line bot" width=344 height=330>

Features:
- Runs in macOS menu bar, works in regular mode and dark mode
- Works with one or more Ecobee thermostats, like the excellent ecobee3
- Allows control of temperature setpoints, fan mode, thermostat mode, readout of sensors
- Has update notification for new versions of ecoBar

Easy Install:
- Download [the installer image] and run it.

BitBar Plugin (Advanced):
- Download and install [BitBar](http://getbitbar.com)
- Install the [Ecobee Gem](https://rubygems.org/gems/ecobee)

To install the ecobee Gem from the command line, run:
```
gem install ecobee
```

Place the file `ecoBar.rb` in your BitBar plugin directory (typically `~/Documents/BitBar`) and rename it to something like `ecobar.1m.rb` for a 1 minute refresh rate. See the [BitBar documentation](https://github.com/matryer/bitbar/blob/master/README.md) for details on customizing BitBar plugins.

TODO:
- Update registration process for instant refresh
- Add more control/display features
