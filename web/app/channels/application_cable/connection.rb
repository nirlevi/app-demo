# frozen_string_literal: true

module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      # For now, allow anonymous connections
      # You can implement JWT token verification here if needed
      
      # Example JWT verification (uncomment if needed):
      # token = request.params[:token] || extract_token_from_headers
      # if token
      #   decoded_token = JWT.decode(token, Rails.application.secrets.secret_key_base, true, { algorithm: 'HS256' })
      #   user_id = decoded_token.first['user_id']
      #   User.find(user_id)
      # else
      #   reject_unauthorized_connection
      # end
      
      "anonymous_#{SecureRandom.hex(8)}"
    end

    def extract_token_from_headers
      # Extract token from Authorization header or query params
      auth_header = request.headers['Authorization']
      auth_header&.split(' ')&.last
    end
  end
end
