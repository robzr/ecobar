module Ecobee
  require 'date' 

  class Token
    attr_reader :access_token, 
                :expires_at, 
                :pin,
                :pin_message,
                :refresh_token,
                :result,
                :status,
                :scope,
                :type

    def initialize(
      app_key: nil, 
      app_name: nil,
      code: nil,
      refresh_token: nil,
      scope: SCOPES[0],
      token_file: nil
    )
      @app_key = app_key
      @app_name = app_name
      @code = code
      @access_token, @code_expires_at, @expires_at, @pin, @type = nil
      @refresh_token = refresh_token
      @scope = scope
      @status = :authorization_pending
      @token_file = File.expand_path(token_file)
      parse_token_file unless @refresh_token
      if @refresh_token
        refresh
      else
        register unless pin_is_valid
        check_for_token
        launch_monitor_thread unless @status == :ready
      end
    end

    def access_token
      refresh if Time.now + REFRESH_INTERVAL_PAD > @expires_at
      @access_token
    end

    def authorization
      "#{@type} #{@access_token}"
    end

    def pin_is_valid
      if @pin && @code && @code_expires_at
        @code_expires_at.to_i >= DateTime.now.strftime('%s').to_i
      else
        false
      end
    end

    def pin_message
      "Log into Ecobee web portal, select My Apps widget, Add Application, " +
      "enter the PIN #{@pin || ''}"
    end

    def refresh
      response = Net::HTTP.post_form(
        URI(URL_TOKEN),
        'grant_type' => 'refresh_token',
        'refresh_token' => @refresh_token,
        'client_id' => @app_key
      )
      result = JSON.parse(response.body)
      if result.key? 'error'
#        pp result
        raise Ecobee::TokenError.new(
          "Result Error: (%s) %s" % [result['error'],
                                     result['error_description']]
        )
      else
        @access_token = result['access_token']
        @expires_at = Time.now + result['expires_in']
        @refresh_token = result['refresh_token']
        @pin, @code, @code_expires_at = nil
        @scope = result['scope']
        @type = result['token_type']
        @status = :ready
        write_token_file
      end
    rescue SocketError => msg
      raise Ecobee::TokenError.new("POST failed: #{msg}")
    rescue JSON::ParserError => msg
      raise Ecobee::TokenError.new("Result parsing: #{msg}")
    rescue Exception => msg
      raise Ecobee::TokenError.new("Unknown Error: #{msg}")
    end

    def wait
      sleep 0.05 while @status == :authorization_pending
      @status
    end

    private

    def check_for_token
      response = Net::HTTP.post_form(
        URI(URL_TOKEN),
        'grant_type' => 'ecobeePin',
        'code' => @code,
        'client_id' => @app_key
      )
      result = JSON.parse(response.body)
      if result.key? 'error'
        unless ['slow_down', 'authorization_pending'].include? result['error']
          # TODO: throttle or just ignore...?
          pp result
          raise Ecobee::TokenError.new(
            "Result Error: (%s) %s" % [result['error'],
                                       result['error_description']]
          )
        end
      else
        @status = :ready
        @access_token = result['access_token']
        @type = result['token_type']
        @expires_at = Time.now + result['expires_in']
        @refresh_token = result['refresh_token']
        @scope = result['scope']
        @pin, @code, @code_expires_at = nil
        write_token_file
      end
    rescue SocketError => msg
      raise Ecobee::TokenError.new("POST failed: #{msg}")
    rescue JSON::ParserError => msg
      raise Ecobee::TokenError.new("Result parsing: #{msg}")
    rescue Exception => msg
      raise Ecobee::TokenError.new("Unknown Error: #{msg}")
    end

    def launch_monitor_thread
      Thread.new {
        loop do
          sleep REFRESH_TOKEN_CHECK
          break if @status == :ready
          check_for_token 
        end
      }
    end

    def parse_token_file
#puts "Before Parse: app_key:#{@app_key} refresh_token:#{@refresh_token} pin:#{pin}"
      return unless (config = read_token_file).is_a? Hash
      section = (@app_name && config.key?(@app_name)) ? @app_name : @app_key
      if config.key?(section)
        @app_key ||= if config[section].key?('app_key') 
                       config[section]['app_key']
                     else
                       @app_name
                     end
        if config[section].key?('refresh_token')
          @refresh_token ||= config[section]['refresh_token']
        elsif config[section].key?('pin')
          @pin ||= config[section]['pin']
          @code ||= config[section]['code']
          @code_expires_at ||= config[section]['code_expires_at'].to_i
        end
      end
#puts "After Parse: app_key:#{@app_key} refresh_token:#{@refresh_token} pin:#{pin}"
    end

    def read_token_file
      JSON.parse(
        File.open(@token_file, 'r').read(16 * 1024)
      )
    rescue Errno::ENOENT
      {}
    end

    def register
      result = Register.new(app_key: @app_key, scope: @scope)
      @pin = result.pin
      @code = result.code
      @code_expires_at = result.expires_at
      @scope = result.scope
      write_token_file
      result
    end

    def write_token_file
      return unless @token_file
      if config = read_token_file
        config.delete(@app_name)
        config.delete(@app_key)
      end
      section = @app_name || @app_key
      config[section] = {}
      config[section]['app_key'] = @app_key if @app_key && section != @app_key
      if @refresh_token
        config[section]['refresh_token'] = @refresh_token 
      elsif @pin
        config[section]['pin'] = @pin
        config[section]['code'] = @code
        config[section]['code_expires_at'] = @code_expires_at
      end
      File.open(@token_file, 'w') do |tf|
        tf.puts JSON.pretty_generate(config)
      end
    end

  end

  class TokenError < StandardError
  end

end
