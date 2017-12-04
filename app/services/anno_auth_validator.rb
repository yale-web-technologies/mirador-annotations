require 'json'
require 'net/http'
require 'jwt'

class AnnoAuthValidator

  def self.authorize(*params)
    new(*params).authorize
  end

  def initialize(auth_header, canvas)
    @auth_header = auth_header
    @canvas = canvas
  end

  # Verfiying from remote destination that the token sent has the same group ID for the canvas and that the user has access
  def authorize
       
    token = decode_token(@auth_header)
    data = get_canvas_data(@canvas, token.first["user_id"])
 
    data["group_id"] == token.first["group_id"] && data["has_access"] == "true"
        
    rescue StandardError => _
      false
  end

  private
    
  attr_reader :auth_header, :canvas

  def decode_token(auth_header)
    auth = auth_header.split(' ').last
    JWT.decode(auth, Rails.application.secrets.jwt_password)
  end

  def get_canvas_data(canvas, user_id)
    base = Rails.application.config.jwt_canvas_verification_url
    url = "#{base}?canvas_id=#{canvas}&user_id=#{user_id}"
    uri = URI(url)
    res = Net::HTTP.get(uri)
    JSON.parse(res).first
  end
end
