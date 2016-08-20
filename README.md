ecoBar
---
Ecobee BitBar plugin for monitoring and controlling an Ecobee thermostat from your macOS menu bar.

<img src="https://raw.githubusercontent.com/robzr/ecobar/master/images/screenshot.png" 
  alt="Example output from one line bot" width=344 height=330>

Features:
- Runs in macOS menu bar, works in regular mode and dark mode
- Works with one or more Ecobee thermostats including the excellent ecobee3
- Allows control of temperature setpoints, fan mode, thermostat mode, readout of sensors
- Sync's Ecobee API token and settings via iCloud Drive if available
- Works with Farenheit or Celcius based on Ecobee setting
- Has update notification for new versions of ecoBar

Standalone Install (Simple):
- Download the [installer image](https://github.com/robzr/ecobar/blob/master/ecoBar.dmg?raw=true) and run it.

Install as a BitBar Plugin (Advanced):
- Download and install [BitBar](http://getbitbar.com)
- Install the [Ecobee Gem](https://rubygems.org/gems/ecobee) by running `gem install ecobee`
- Place the file `ecoBar.rb` and directory `eco_bar` in your BitBar plugin directory (typically `~/Documents/BitBar`)
- Rename the plugin to something like `ecobar.1m.rb` for a 1 minute refresh rate.
- See [BitBar documentation](https://github.com/matryer/bitbar/blob/master/README.md) for details on customizing BitBar plugins

TODO:
- rewriting file load/save logic for better cloud awareness, to avoid token collisions
- Update registration process for instant refresh
- Add more control/display features
