#!/usr/bin/env ruby
#
# <bitbar.title>ecoBar</bitbar.title>
# <bitbar.version>v0.1.0</bitbar.version>
# <bitbar.author>Rob Zwissler</bitbar.author>
# <bitbar.author.github>robzr</bitbar.author.github>
# <bitbar.desc>Ecobee Thermostat Control</bitbar.desc>
# <bitbar.image>https://raw.githubusercontent.com/robzr/ecobar/master/images/screenshot.png</bitbar.image>
# <bitbar.dependencies>Ruby</bitbar.dependencies>
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
  puts 'Wait a few minutes'
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
  begin
    File.unlink(*Ecobee::DEFAULT_FILES.map { |tf| File.expand_path tf }) 
  rescue
  end
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
  ecobar.separator
  ecobar.about
end
