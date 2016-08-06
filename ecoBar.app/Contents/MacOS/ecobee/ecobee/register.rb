module Ecobee
  require 'date'

  class Register
    attr_reader :expires_at, :result

    def initialize(app_key: nil, scope: SCOPES[0])
      raise ArgumentError.new('Missing app_key') unless app_key
      @result = get_pin(app_key: app_key, scope: scope)
      @expires_at = DateTime.now.strftime('%s').to_i + result['expires_in'] * 60
    end

    def code
      @result['code']
    end

    def interval
      @result['interval']
    end

    def pin
      @result['ecobeePin']
    end

    def scope
      @result['scope']
    end

    private 

    def get_pin(app_key: nil, scope: nil)
      uri_pin = URI(URL_GET_PIN % [app_key, scope.to_s])
      result = JSON.parse Net::HTTP.get(uri_pin)
      if result.key? 'error'
        raise Ecobee::TokenError.new(
          "Register Error: (%s) %s" % [result['error'], result['error_description']]
        )
      end
      result
    rescue SocketError => msg
      raise Ecobee::TokenError.new("GET failed: #{msg}")
    rescue JSON::ParserError => msg
      raise Ecobee::TokenError.new("Parse Error: #{msg}")
    rescue Exception => msg
      raise Ecobee::TokenError.new("Unknown Error: #{msg}")
    end
  end

end
