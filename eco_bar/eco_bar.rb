require_relative 'eco_bar/auto_update.rb'
require_relative 'eco_bar/bar_io.rb'
require_relative 'eco_bar/icons.rb'
require_relative 'eco_bar/version.rb'

module EcoBar
  APP_KEY = 'MKDvfwwyGib0ZFhUdgKP4wDIRzYooM1o'
  COLOR = {
    cold:  { true => '#1010ff', false => '#0000c0' },
    dark:  { true => '#ffffff', false => '#000000' }, 
    hot:   { true => '#ff1010', false => '#c00000' },
    light: { true => '#404040', false => '#707070' }
  }


  ECOBEE_URL = 'https://www.ecobee.com/consumerportal/index.html'

  GITHUB_URL = 'https://github.com/robzr/ecobar'

  GITHUB_DMG_URL = GITHUB_URL + '/raw/master/ecoBar.dmg'

  UPDATE_CHECK_URL = 'https://raw.githubusercontent.com/robzr/ecobar/master/' +
                     'eco_bar/eco_bar/version.rb'

  DEG = '°'
  CHECK = '✓' # ':heavy_check_mark:'
  POINT = ':point_left:'
  SNOWFLAKE = ':snowflake:'
  FLAME = ':fire:'

  class ResponseError < StandardError ; end
end
