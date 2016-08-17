require_relative 'eco_bar/bar_io.rb'
require_relative 'eco_bar/icons.rb'
require_relative 'eco_bar/version.rb'

module EcoBar
  APP_KEY = 'MKDvfwwyGib0ZFhUdgKP4wDIRzYooM1o'
  DEG = '°'
  CHECK = '✓'
#  CHECK = ':heavy_check_mark:'
  POINT = ':point_left:'
  SNOWFLAKE = ':snowflake:'
  FLAME = ':fire:'

  class ResponseError < StandardError ; end
end
