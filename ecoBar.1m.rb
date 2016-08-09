#!/usr/bin/env ruby
#
# Allows for display and control of your Ecobee in the Mac OS X 
# menubar, using BitBar (http://getbitbar.com).   -- @robzr
#
# <bitbar.title>EcobeeStat</bitbar.title>
# <bitbar.version>v1.0</bitbar.version>
# <bitbar.author>Rob Zwissler</bitbar.author>
# <bitbar.author.github>robzr</bitbar.author.github>
# <bitbar.desc>Ecobee Thermostat Control</bitbar.desc>
# <bitbar.image>http://github.com/robzr/ecobee</bitbar.image>
# <bitbar.dependencies>ruby</bitbar.dependencies>
# <bitbar.abouturl>http://github.com/robzr/ecobee</bitbar.abouturl>

require 'pp'
#require 'ecobee'
require_relative '/Users/robzr/GitHub/ecobee/lib/ecobee.rb'

APP_KEY = 'MKDvfwwyGib0ZFhUdgKP4wDIRzYooM1o'
DEG = '°'

module Ecobee
  class ResponseError < StandardError ; end

  class BitBar
    def initialize(client)
      @client = client
    end

    def get_thermostat(args = {})
      index = args.delete(:index) || 0
      response = @client.get('thermostat', Ecobee::Selection(args))
      get_thermostat_list_index(index: index, response: response)
    end

    def get_thermostat_list_index(index: 0, response: nil)
      if !response.key? 'thermostatList'
        raise ResponseError.new('Missing thermostatList')
      elsif index >= response['thermostatList'].length
        raise ResponseError.new(
          "Missing thermostatList Index #{index} (Max Found: " +
          "#{response['thermostatList'].length - 1})"
        )
      else
        response['thermostatList'][index]
      end
    end

#      puts "Heat: #{info['runtime']['desiredHeat'] / 10}#{DEG} | color=red"

    def set_hold(cool_hold: nil, heat_hold: nil)
      functions = [{
        'type' => 'setHold',
        'params' => {
          'holdType' => 'nextTransition',
        }
      }]
      functions[0]['params']['coolHoldTemp'] = cool_hold
      functions[0]['params']['heatHoldTemp'] = heat_hold
      @client.post(
        'thermostat', 
        body: { 
          'selection' => {
            'selectionType' => 'registered',
            'selectionMatch' => '',
          },
          'functions' => functions
        }
      )
    end

    def update_mode(mode)
      @client.post(
        'thermostat', 
        body: { 
          'selection' => {
            'selectionType' => 'registered',
            'selectionMatch' => '',
          },
          'thermostat' => {
            'settings' => {
              'hvacMode' => mode
            }
          }
        }
      )
    end
  end
end

def header(info)
  puts "#{info['runtime']['actualTemperature'] / 10.0}#{DEG}"
  puts '---'
end

def cool_menu(info)
  present_mode = info['settings']['hvacMode']
  return unless ['auto', 'cool'].include? present_mode
  puts "Cool: #{info['runtime']['desiredCool'] / 10}#{DEG} | color=blue"
  cool_low = info['settings']['coolRangeLow'] / 10
  cool_high = info['settings']['coolRangeHigh'] / 10
  (cool_low..cool_high).reverse_each do |temp|
    flag, color = ''
    flag = ' :arrow_left:' if temp == info['runtime']['actualTemperature'] / 10
    color = ' color=blue' if temp == info['runtime']['desiredCool'] / 10
    puts("--#{temp}#{DEG}#{flag}|#{color} bash=\"#{$0}\" " +
         "param1=\"set_cool=#{temp}\" refresh=true terminal=false")
  end
end

def heat_menu(info)
  present_mode = info['settings']['hvacMode']
  return unless ['auto', 'auxHeatOnly', 'heat'].include? present_mode
  puts "Heat: #{info['runtime']['desiredHeat'] / 10}#{DEG} | color=red"
  heat_low = info['settings']['heatRangeLow'] / 10
  heat_high = info['settings']['heatRangeHigh'] / 10
  (heat_low..heat_high).reverse_each do |temp|
    flag, color = ''
    flag = ' :arrow_left:' if temp == info['runtime']['actualTemperature'] / 10
    color = ' color=red' if temp == info['runtime']['desiredHeat'] / 10
    puts("--#{temp}#{DEG}#{flag}|#{color} bash=\"#{$0}\" " +
         "param1=\"set_heat=#{temp}\" refresh=true terminal=false")
  end
end

def mode_menu(info)
  puts "Mode: #{info['settings']['hvacMode']}"
  Ecobee::HVAC_MODES.reject { |mode| mode == info['settings']['hvacMode'] }
    .each do |mode|
      puts("--#{mode} | bash=\"#{$0}\" param1=\"set_mode=#{mode}\" " +
           "refresh=true terminal=false")
  end
end

def separator
  puts '---'
end

def stat_info(info)
  puts info['name'] 
  info['remoteSensors'].each do |sensor|
    temp = sensor['capability'].select do |cap|
      cap['type'] == 'temperature'
    end
    temp = temp[0]['value'].to_i / 10.0
    puts "--#{sensor['name']}: #{temp}#{DEG}"
  end
  puts "#{info['brand']} #{Ecobee::Model(info['modelNumber'])}"
  puts "Status: #{info['equipmentStatus']}"
end

def website
  puts 'Ecobee Web Portal|href="https://www.ecobee.com/consumerportal/index.html"'
end

token = Ecobee::Token.new(
  app_key: APP_KEY,
  scope: :smartWrite,
)
if token.pin
  puts "ecoBar | color=red"
  puts "---"
  puts "Registration Needed | color=red"
  puts "---"
  puts 'Login to Ecobee | href=\'https://www.ecobee.com/consumerportal/index.html\''
  puts 'Select \'My Apps\' from the drop-down menu'
  puts 'Press the \'Add Application\' button'
  puts "Enter authorization code: #{token.pin}"
  exit
end

ecobar = Ecobee::BitBar.new Ecobee::Client.new(token: token)

case arg = ARGV.shift 
when /^dump/
  pp ecobar.get_thermostat(
    :includeRuntime => true,
    :includeExtendedRuntime => true,
    :includeElectricity => true,
    :includeSettings => true,
    :includeLocation => true,
    :includeProgram => true,
    :includeEvents => true,
    :includeDevice => true,
    :includeTechnician => true,
    :includeUtility => true,
    :includeAlerts => true,
    :includeWeather => true,
    :includeOemConfig => true,
    :includeEquipmentStatus => true,
    :includeNotificationSettings => true,
    :includeVersion => true,
    :includeSensors => true
  )
when /^set_mode=/
  mode = arg.sub(/^.*=/, '')
  ecobar.update_mode mode
when /^set_cool=/
  info = ecobar.get_thermostat(includeRuntime: true,
                               includeSettings: true)
  cool_hold = arg.sub(/^.*=/, '').to_i * 10
  heat_hold = info['runtime']['desiredHeat']

  ecobar.set_hold(cool_hold: cool_hold, heat_hold: heat_hold)
when /^set_heat=/
  info = ecobar.get_thermostat(includeRuntime: true,
                               includeSettings: true)
  cool_hold = info['runtime']['desiredCool']
  heat_hold = arg.sub(/^.*=/, '').to_i * 10

  ecobar.set_hold(cool_hold: cool_hold, heat_hold: heat_hold)
else
  info = ecobar.get_thermostat(includeRuntime: true,
                               includeSettings: true,
                               includeEquipmentStatus: true,
                               includeSensors: true)
  header info
  cool_menu info
  heat_menu info
  separator
  stat_info info
  mode_menu info
  separator
  website
end
