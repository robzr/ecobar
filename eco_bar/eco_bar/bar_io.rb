module EcoBar
  class BarIO
    attr_accessor :index
    attr_reader :max_index, :thermostats

    def initialize(
      client: nil,
      index: 0,
      thermostats: nil,
      token: nil
    )
      @client = client
      @token = token
      @thermostats = thermostats || load_thermostats
      @index = [index, max_index].min
      @base_command = %Q{bash="#{$0}" refresh=true terminal=false}
    end

    def header
      puts "#{thermostat.temperature}#{DEG}"
      puts '---'
    end

    def setpoint_menu
      if ['auto', 'cool'].include? thermostat.mode
        puts "Cool Setpoint: #{thermostat.desired_cool}#{DEG} | #{color(:cold)}"
        setpoint_menu_cool
      end
      if ['auto', 'auxHeatOnly', 'heat'].include? thermostat.mode
        puts "Heat Setpoint: #{thermostat.desired_heat}#{DEG} | #{color(:hot)}"
        setpoint_menu_heat
      end
    end

    def setpoint_menu_cool
      thermostat.cool_range(with_delta: true).reverse_each do |temp|
        if temp == thermostat.desired_cool
          line = "--#{CHECK} #{temp}#{DEG}| trim=false #{color(:cold)}"
        else
          line = "--    #{temp}#{DEG}| trim=false #{color(:cold)} " +
                 "#{@base_command} param1=set_cool=#{temp}"
        end
        puts line
      end
    end

    def setpoint_menu_heat
      thermostat.heat_range(with_delta: true).reverse_each do |temp|
        if temp == thermostat.desired_heat
          line = "--#{CHECK} #{temp}#{DEG}| trim=false #{color(:hot)}"
        else
          line = "--    #{temp}#{DEG}| trim=false #{color(:hot)} " +
                 "#{@base_command} param1=set_heat=#{temp}"
        end
        puts line
      end
    end

    def thermostat
      @thermostats[@index]
    end

    def max_index
      @thermostats[0].max_index
    end

    def mode_menu
      puts "Mode (#{Ecobee::Mode(thermostat.mode)})"
      Ecobee::HVAC_MODES.each do |mode|
        if mode == thermostat.mode
          line = "--#{CHECK} #{Ecobee::Mode(mode)}| trim=false #{color(:dark)}"
        else
          line = "--    #{Ecobee::Mode(mode)}| trim=false #{color(:dark)} " +
                 %Q{#{@base_command} param1="set_mode=#{mode}"}
        end
        puts line
      end
    end

    def max_index
      @thermostats[0].max_index
    end

    def color(type)
      'color=' + case type
                 when :hot
                   dark_mode ? '#ff1010': '#c00000'
                 when :cold
                   dark_mode ? '#1010ff' : '#0000c0'
                 when :dark
                   dark_mode ? '#ffffff' : '#000000'
                 when :light
                   dark_mode ? '#404040' : '#707070'
                 end
    end

    def dark_mode
      ENV['BitBarDarkMode'] == '1'
    end

    def fan_mode
      puts("Fan Mode (#{Ecobee::FanMode(thermostat.desired_fan_mode)})| " +
           "trim=false #{color(:dark)}")
      Ecobee::FAN_MODES.each do |mode|
        if mode == thermostat.desired_fan_mode
          line = "--#{CHECK} #{Ecobee::FanMode(mode)}| trim=false #{color(:dark)}"
        else
          line = "--    #{Ecobee::FanMode(mode)}| trim=false #{color(:dark)} " +
                 "#{@base_command} param1=set_fan_mode=#{mode}"
        end
        puts line
      end
    end

    def name_menu
      puts "#{thermostat.name} (#{thermostat.model}) | #{color(:dark)}"
      if max_index > 0
        @thermostats.each_index do |index|
          thermostat = @thermostats[index]
          
          if @index == index
            line = "--#{CHECK} #{thermostat.name} (#{thermostat.model})| " +
                   "trim=false #{color(:dark)}"
          else
            line = "--    #{thermostat.name} (#{thermostat.model})| trim=false" +
                   " #{color(:dark)} #{@base_command} param1=set_index=#{index}"
          end
          puts line
        end
      end
    end

    def sensors
      puts 'Sensors'
      thermostat[:remoteSensors].sort { |a,b| a[:name] <=> b[:name] }
        .each do |sensor|
          line = "--#{sensor[:name]}:"
          val = sensor[:capability].select { |cap| cap[:type] == 'temperature' }
          line += %Q{ #{val[0][:value].to_i / 10.0}#{DEG}} if val.length > 0
          val = sensor[:capability].select { |cap| cap[:type] == 'humidity' }
          line += %Q{ #{val[0][:value].to_i }%} if val.length > 0
          puts line + "| #{color(:dark)}"
        end
    end

    def separator
      puts '---'
    end

    def status
      puts "Status (#{thermostat[:equipmentStatus]}) | #{color(:dark)}"
    end

    def website
      puts 'Ecobee Web Portal|href="https://www.ecobee.com/consumerportal/index.html"'
    end

    private

    def load_thermostats
      @client ||= Ecobee::Client.new(token: @token)
#      thermostats = [Ecobee::Thermostat.new(client: @client, fake_max_index: 1)]
#      thermostats << Ecobee::Thermostat.new(client: @client, fake_index: 1, fake_max_index: 1)
      thermostats = [Ecobee::Thermostat.new(client: @client)]
      (1..thermostats[0].max_index).each do |index|
        thermostats[index] = Ecobee::Thermostat.new(client: @client, index: index)
      end
      thermostats
    end
  end
end
