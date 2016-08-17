ecoBar
---
Ecobee BitBar Plugin for monitoring and controlling an Ecobee thermostat.

<img src="https://raw.githubusercontent.com/robzr/ecobar/master/images/screenshot.png" 
  alt="Example output from one line bot" width=321 height=419>

Requires:
- [BitBar](http://getbitbar.com)
- [Ecobee Gem](http://getbitbar.com)

To install the ecobee Gem, run:
```
gem install ecobee
```

Place the file `ecobar.1m.rb` in your BitBar plugin directory (typically `~/Documents/BitBar`)

TODO:
- (done) Add ecoBee menubar image icons
- Update to use Ecobee::Thermostat abstraction class
- Merge Cool/Heat into single Set Point (?) with only available temps.
- Add "refresh=true" + wait to registration process for instant refresh
- Add Fan override (Fan: On / Auto)
- Add Mode human readable translation "Off" "Heat" "Cool" "Auto" "Aux Heat" based on capabilities
- Add multiple thermostat support
- Add display preferences into save file (incl. thermostat #)
