module EcoBar
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
          'functions' => functions
        }.merge(Ecobee::Selection)
      )
    end

    def update_mode(mode)
      @client.post(
        'thermostat', 
        body: { 
          'thermostat' => {
            'settings' => {
              'hvacMode' => mode
            }
          }
        }.merge(Ecobee::Selection)
      )
    end
  end
end
