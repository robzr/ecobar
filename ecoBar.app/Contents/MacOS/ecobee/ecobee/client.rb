module Ecobee

  class Client

    def initialize(token: nil)
      raise ArgumentError.new('Missing token') unless token
      @token = token
    end

    def get(arg, options = nil)
      new_uri = URL_API + arg.sub(/^\//, '')
      new_uri += '?json=' + options.to_json if options

      request = Net::HTTP::Get.new(URI(URI.escape(new_uri)))
      request['Content-Type'] = *CONTENT_TYPE
      request['Authorization'] = @token.authorization
      http.request(request)
    end

    def post(arg, options: {}, body: nil)
      new_uri = URL_API + arg.sub(/^\//, '')
      request = Net::HTTP::Post.new(URI new_uri)
      request.set_form_data({ 'format' => 'json' }.merge(options))
      request.body = JSON.generate(body) if body
      request['Content-Type'] = *CONTENT_TYPE
      request['Authorization'] = @token.authorization
      http.request(request)
    end

    private

    def http
      @http ||= Net::HTTP.new(API_HOST, API_PORT)
      unless @http.active? 
        @http.use_ssl = true
        Net::HTTP.start(API_HOST, API_PORT)
      end
      @http
    end

  end

end
