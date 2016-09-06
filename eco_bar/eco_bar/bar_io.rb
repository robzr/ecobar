module EcoBar

  require 'fileutils'

  class BarIO
    attr_accessor :index
    attr_reader :max_index, :thermostats

    def initialize(
      index: 0,
      thermostats: nil,
      token: nil
    )
      @token = token
      @thermostats = thermostats || load_thermostats
      @index = [index, max_index].min

      @base_command = %Q{bash="#{$0}" refresh=true terminal=false}

      #check_for_sfmono
    end

    def about
      render("ecoBar v#{VERSION}", color: :dark, href: GITHUB_URL)
      render('Update Available',
             color: :hot,
             param1: 'update',
             run_self: true) unless AutoUpdate.new.up_to_date?
    end

    def alerts
      return unless thermostat[:alerts].length > 0
      render("#{thermostat[:alerts].length} Alerts Present", color: :hot)
      thermostat[:alerts].each do |alert|
        render("--#{alert[:date]} #{alert[:time]} #{alert[:text]}",
               color: :hot,
               param1: "acknowledge=#{alert[:acknowledgeRef]}",
               run_self: true)
      end
    end

    def check_for_sfmono
      font = 'SFMono-Regular.otf'
      font_dest_path = "#{File.expand_path '~'}/Library/Fonts"
      font_dest = "#{font_dest_path}/#{font}"
      font_src = [
        "/Applications/Utilities/Console.app/Contents/Resources/Fonts/#{font}",
        "/Applications/Utilities/Terminal.app/Contents/Resources/Fonts/#{font}"
      ].select { |src| File.readable? src }.first
      if font_src && !File.exists?(font_dest) && File.writable?(font_dest_path)
        FileUtils.cp(font_src, font_dest)
      end
      @font = 'SFMono-Regular' if File.exists? font_dest
    end

    def check(checked)
      case @font
      when 'SFMono-Regular'
        checked ? "#{CHECK} " : ' ' * 2
      else
        checked ? "#{CHECK} " : ' ' * 4
      end
    end

    def color(type)
      "color=#{COLOR[type][dark_mode]}"
    end

    def dark_mode
      ENV['BitBarDarkMode'] == '1'
    end

    def fan_mode
      render("Fan Mode: #{Ecobee::FanMode(thermostat.desired_fan_mode)}",
             color: :dark)
      Ecobee::FAN_MODES.each do |mode|
        if mode == thermostat.desired_fan_mode
          render("--#{check true}#{Ecobee::FanMode(mode)}", color: :dark)
        else
          render("--#{check false}#{Ecobee::FanMode(mode)}",
                 color: :dark,
                 param1: "set_fan_mode=#{mode}",
                 run_self: true)
        end
      end
    end

    def header
      puts "#{thermostat.temperature}#{DEG}\n---"
    end

    def max_index
      @thermostats[0] ?  @thermostats[0].max_index : -1
    end

    def mode_menu
      render "Mode: #{Ecobee::Mode(thermostat.mode)}"
      Ecobee::HVAC_MODES.each do |mode|
        if mode == thermostat.mode
          render("--#{check true}#{Ecobee::Mode(mode)}", color: :dark)
        else
          render("--#{check false}#{Ecobee::Mode(mode)}",
                 color: :dark,
                 param1: "set_mode=#{mode}",
                 run_self: true)
        end
      end
    end

    def name_menu
      render("#{thermostat.name} (#{thermostat.model})", color: :dark)
      if max_index > 0
        @thermostats.each_index do |index|
          thermostat = @thermostats[index]
          
          if @index == index
            render("--#{check true}#{thermostat.name} (#{thermostat.model})",
                   color: :dark)
          else
            render("--#{check false}#{thermostat.name} (#{thermostat.model})",
                   color: :dark,
                   param1: "set_index=#{index}",
                   run_self: true)
          end
        end
      end
    end

    def render(msg, *args)
      msg += '|'
      if (arg = args.shift).is_a? Hash
        msg += " #{arg[:attrib]}" if arg.key? :attrib
        msg += " bash=\"#{arg[:bash]}\"" if arg.key? :bash
        msg += " #{color(arg[:color])}" if arg.key? :color
        if arg.key? :font
          msg += " font=#{arg[:font]}"
        elsif @font
          msg += " font=#{@font}"
        end
        msg += " href=\"#{arg[:href]}\"" if arg.key? :href
        msg += " #{@base_command}" if arg.key? :run_self
        msg += " trim=#{arg[:trim] ? 'true' : 'false'}"
        arg.keys.sort.select do |key| 
          if key.to_s =~ /^param(\d+)/
            msg += " param#{$1}=#{arg[key]}"
          end
        end
      end
      puts msg
    end

    def sensors
      puts 'Sensors'
      thermostat[:remoteSensors].sort { |a,b| a[:name] <=> b[:name] }
        .each do |sensor|
          msg = "--#{sensor[:name]}:"
          val = sensor[:capability].select { |cap| cap[:type] == 'temperature' }
          msg += %Q{ #{thermostat.unitize(val[0][:value])}#{DEG}} if val.length > 0
          val = sensor[:capability].select { |cap| cap[:type] == 'humidity' }
          msg += %Q{ #{val[0][:value].to_i}%} if val.length > 0
          render(msg, color: :dark)
        end
    end

    def setpoint_menu
      if ['auto', 'cool'].include? thermostat.mode
        render("Cool Setpoint: #{thermostat.desired_cool}#{DEG}", color: :cold)
        setpoint_menu_cool
      end
      if ['auto', 'auxHeatOnly', 'heat'].include? thermostat.mode
        render("Heat Setpoint: #{thermostat.desired_heat}#{DEG}", color: :hot)
        setpoint_menu_heat
      end
    end

    def setpoint_menu_cool
      thermostat.cool_range(with_delta: true).reverse_each do |temp|
        if temp == thermostat.desired_cool
          render("--#{check true}#{temp}#{DEG}", color: :cold)
        else
          render("--#{check false}#{temp}#{DEG}",
                 color: :cold,
                 param1: "set_cool=#{temp}",
                 run_self: true)
        end
      end
    end

    def setpoint_menu_heat
      thermostat.heat_range(with_delta: true).reverse_each do |temp|
        if temp == thermostat.desired_heat
          render("--#{check true}#{temp}#{DEG}", color: :hot)
        else
          render("--#{check false}#{temp}#{DEG}", 
                 color: :hot,
                 param1: "set_heat=#{temp}",
                 run_self: true)
        end
      end
    end

    def separator
      puts '---'
    end

    def status
      status = thermostat[:equipmentStatus]
      status = 'none' if status == ''
      render("Status: #{status}", color: :dark)
    end

    def thermostat
      @thermostats[@index]
    end

    def weather
      forecast = thermostat[:weather][:forecasts][0]
      unit_temp = thermostat.unitize(forecast[:temperature])
      render("Weather: #{unit_temp}#{DEG} #{forecast[:relativeHumidity]}%",
            href: "https://www.wunderground.com/cgi-bin/findweather/" +
                  "getForecast?query=#{thermostat[:location][:mapCoordinates]}")
      render("--#{forecast[:condition]}", color: :dark)
      render("--Low temp of #{thermostat.unitize(forecast[:tempLow])}#{DEG}",
             color: :dark)
      render("--High temp of #{thermostat.unitize(forecast[:tempHigh])}#{DEG}",
             color: :dark)
      render("--Wind blowing #{forecast[:windDirection]} at " +
             "#{forecast[:windSpeed] / 1000} mph", 
             color: :dark)
    end

    def website
      render('Ecobee Web Portal', href: ECOBEE_URL)
    end

    private

    def load_thermostats
#      thermostats = [Ecobee::Thermostat.new(token: @token, fake_max_index: 1)]
#      thermostats << Ecobee::Thermostat.new(token: @token, fake_index: 1, fake_max_index: 1)
      thermostats = [Ecobee::Thermostat.new(token: @token)]
      (1..thermostats[0].max_index).each do |index|
        thermostats[index] = Ecobee::Thermostat.new(index: index, token: @token)
      end
      thermostats
    end

  end

end
