#!/usr/bin/env ruby
# # Allows for display and control of your Ecobee in the Mac OS X 
# menubar, using BitBar (http://getbitbar.com).   -- @robzr
#
# <bitbar.title>ecoBar</bitbar.title>
# <bitbar.version>v1.0</bitbar.version>
# <bitbar.author>Rob Zwissler</bitbar.author>
# <bitbar.author.github>robzr</bitbar.author.github>
# <bitbar.desc>Ecobee Thermostat Control</bitbar.desc>
# <bitbar.image>http://github.com/robzr/ecobee</bitbar.image>
# <bitbar.dependencies>ruby</bitbar.dependencies>
# <bitbar.abouturl>http://github.com/robzr/ecobar</bitbar.abouturl>

require 'pp'
require_relative 'ecobee/ecobee'
require_relative 'eco_bar/eco_bar'

@config = { 'index' => 0 }

config_load = lambda do |config|
  @config.merge!(config['ecoBar'].to_h)
  config
end

config_save = lambda do |config|
  config['ecoBar'] = @config
  config
end

@token = Ecobee::Token.new(
  app_key: EcoBar::APP_KEY,
  callbacks: {
    load: config_load,
    save: config_save,
  },
  scope: :smartWrite
)

if @token.pin
  puts "|dropdown=false templateImage=#{EcoBar::Icons::MENU_30}"
  puts '---'
  puts 'Registration Needed | color=red'
  puts '---'
  # TODO: Add hook for watcher script
  puts 'Login to Ecobee | href=\'https://www.ecobee.com/home/ecobeeLogin.jsp\''
  puts "Add Application with code #{@token.pin} | href=\'https://www.ecobee.com/consumerportal/index.html#/my-apps/add/new\'"
  exit
end

ecobar = EcoBar::BarIO.new(index: @config['index'],
                           token: @token)

case arg = ARGV.shift 
when /^dump/
  pp ecobar.thermostat
#  pp(ecobar.thermostat[:events]
#       .select do |event|
#         event[:running] == true
#       end[0])
when /^wipe_tokens/
  `rm -f ~'/Library/Mobile Documents/com~apple~CloudDocs/.ecobee_token' ~'/.ecobee_token'`
when /^set_index=/
  @config['index'] = [arg.sub(/^.*=/, '').to_i, ecobar.max_index].min.to_i
  @token.config_save
when /^set_mode=/
  ecobar.thermostat.mode = arg.sub(/^.*=/, '')
when /^set_cool=/
  ecobar.thermostat.desired_cool = arg.sub(/^.*=/, '')
when /^set_heat=/
  ecobar.thermostat.desired_heat = arg.sub(/^.*=/, '')
when /^set_fan_mode=/
  ecobar.thermostat.desired_fan_mode = arg.sub(/^.*=/, '')
else
  ecobar.header
  ecobar.setpoint_menu
  ecobar.separator
  ecobar.name_menu
  ecobar.status
  ecobar.mode_menu
  ecobar.fan_mode
  ecobar.sensors
  ecobar.separator
  ecobar.website
end
