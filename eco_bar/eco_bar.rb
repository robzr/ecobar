require_relative 'eco_bar/auto_update.rb'
require_relative 'eco_bar/bar_io.rb'
require_relative 'eco_bar/icons.rb'
require_relative 'eco_bar/version.rb'

module EcoBar
  APP_KEY = 'MKDvfwwyGib0ZFhUdgKP4wDIRzYooM1o'
  HOMEPAGE = 'https://github.com/robzr/ecobar'
  UPDATE_CHECK_URL = 'https://raw.githubusercontent.com/robzr/ecobar/master/' +
                     'eco_bar/eco_bar/version.rb'
  DMG_URL = 'https://github.com/robzr/ecobar/raw/master/ecoBar.dmg'

  DEG = '°'
  CHECK = '✓'   # ':heavy_check_mark:'
  POINT = ':point_left:'
  SNOWFLAKE = ':snowflake:'
  FLAME = ':fire:'

  class ResponseError < StandardError ; end
end
