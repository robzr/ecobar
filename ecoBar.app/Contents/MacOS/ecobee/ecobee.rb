require 'pp'
require 'json'
require 'net/http'

require_relative "ecobee/client"
require_relative "ecobee/register"
require_relative "ecobee/token"
require_relative "ecobee/version"

module Ecobee
  API_HOST = 'api.ecobee.com'
  API_PORT = 443
  CONTENT_TYPE = ['application/json', { 'charset' => 'UTF-8' }]

  HVAC_MODES = ['auto', 'auxHeatOnly', 'cool', 'heat', 'off']

  REFRESH_INTERVAL_PAD = 60
  REFRESH_TOKEN_CHECK = 10 

  SCOPES = [:smartRead, :smartWrite]
  
  URL_BASE= "https://#{API_HOST}:#{API_PORT}"

  URL_API = "#{URL_BASE}/1/"
  URL_GET_PIN = URL_BASE + 
    '/authorize?response_type=ecobeePin&client_id=%s&scope=%s'
  URL_TOKEN = "#{URL_BASE}/token"


  def self.Model(model)
    { 'idtSmart'    => 'ecobee Smart',
      'idtEms'      => 'ecobee Smart EMS',
      'siSmart'     => 'ecobee Si Smart',
      'siEms'       => 'ecobee Si EMS',
      'athenaSmart' => 'ecobee3 Smart',
      'athenaEms'   => 'ecobee3 EMS',
      'corSmart'    => 'Carrier or Bryant Cor',
    }[model] || 'Unknown'
  end

  def self.ResponseCode(code)
    {  0 => 'Success',
       1 => 'Authentication failed.', 
       2 => 'Not authorized.',
       3 => 'Processing error.',
       4 => 'Serialization error.',
       5 => 'Invalid request format.',
       6 => 'Too many thermostat in selection match criteria.',
       7 => 'Validation error.',
       8 => 'Invalid function.',
       9 => 'Invalid selection.',
      10 => 'Invalid page.',
      11 => 'Function error.',
      12 => 'Post not supported for request.',
      13 => 'Get not supported for request.',
      14 => 'Authentication token has expired. Refresh your tokens.',
      15 => 'Duplicate data violation.',
      16 => 'Invalid token. Token has been deauthorized by user. You must ' +
            're-request authorization.'
    }[code] || 'Unknown Error.'
  end

  def self.Selection(arg = {})
    { 'selection' => {
        'selectionType' => 'registered',
        'selectionMatch' => '',
        'includeRuntime' => 'false',
        'includeExtendedRuntime' => 'false',
        'includeElectricity' => 'false',
        'includeSettings' => 'false',
        'includeLocation' => 'false',
        'includeProgram' => 'false',
        'includeEvents' => 'false',
        'includeDevice' => 'false',
        'includeTechnician' => 'false',
        'includeUtility' => 'false',
        'includeAlerts' => 'false',
        'includeWeather' => 'false',
        'includeOemConfig' => 'false',
        'includeEquipmentStatus' => 'false',
        'includeNotificationSettings' => 'false',
        'includeVersion' => 'false',
        'includeSensors' => 'false',
      }.merge(Hash[*arg.map { |k,v| [k.to_s, v.to_s] }.flatten])
    }
  end

end
