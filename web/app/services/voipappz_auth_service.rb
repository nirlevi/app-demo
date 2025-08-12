# frozen_string_literal: true

# VoipAppz Authentication Service
# Handles authentication with the VoipAppz platform and user synchronization
class VoipappzAuthService < ApplicationService
  # Custom exceptions for authentication errors
  class AuthenticationError < StandardError; end
  class InvalidTokenError < AuthenticationError; end
  class ExpiredTokenError < AuthenticationError; end
  class InsufficientPermissionsError < AuthenticationError; end

  def initialize(token:)
    super
    @token = token
  end

  def call
    validate_and_decode_token
  end

  class << self
    # Verify a VoipAppz JWT token and return user data
    # @param token [String] JWT token from VoipAppz platform
    # @return [Hash] decoded user and organization data
    # @raise [InvalidTokenError] if token is invalid
    def verify_token(token)
      new(token: token).call
    end

    # Create a mock token for development/testing
    # @param user_data [Hash] user data to encode
    # @return [String] mock JWT token
    def create_mock_token(user_data = {})
      return nil unless Rails.env.development? || Rails.env.test?
      
      default_data = {
        user_id: 'test_user_123',
        email: 'test@voipappz.io',
        first_name: 'Test',
        last_name: 'User',
        role: 'admin',
        organization_id: 'org_456',
        organization_name: 'Test Organization',
        permissions: ['calls:read', 'calls:write', 'dashboard:read', 'users:manage'],
        exp: 1.day.from_now.to_i,
        iat: Time.current.to_i
      }
      
      payload = default_data.merge(user_data)
      encode_mock_jwt(payload)
    end

    private

    # Encode a mock JWT for development
    # In production, this would be handled by VoipAppz platform
    def encode_mock_jwt(payload)
      # Simple Base64 encoding for development (NOT secure for production)
      Base64.strict_encode64(payload.to_json)
    end
  end

  private

  attr_reader :token

  def validate_and_decode_token
    return decode_mock_token if mock_token?
    decode_voipappz_token
  end

  # Check if this is a mock token (development/test)
  def mock_token?
    (Rails.env.development? || Rails.env.test?) && 
      ENV['VOIPAPPZ_USE_MOCK_AUTH'].present?
  end

  # Decode mock token for development
  def decode_mock_token
    decoded = Base64.strict_decode64(token)
    JSON.parse(decoded).with_indifferent_access
  rescue StandardError => e
    Rails.logger.error("Mock token decode failed: #{e.message}")
    raise InvalidTokenError, "Invalid mock token format"
  end

  # Decode real VoipAppz JWT token
  def decode_voipappz_token
    # TODO: Implement real JWT verification with VoipAppz public key
    # This would typically involve:
    # 1. Fetching VoipAppz public key from devzone.voipappz.io
    # 2. Verifying JWT signature
    # 3. Checking token expiration
    # 4. Validating issuer and audience
    
    # For now, make API call to VoipAppz to verify token
    verify_token_with_voipappz_api
  end

  # Verify token with VoipAppz API
  def verify_token_with_voipappz_api
    # Use VoipAppz client to verify token
    client = build_auth_client
    
    response = client.verify_user_token(token)
    
    if response && response[:valid]
      response[:user_data].with_indifferent_access
    else
      raise InvalidTokenError, "Token verification failed"
    end
  rescue VoipappzClient::UnauthorizedError
    raise InvalidTokenError, "Invalid or expired token"
  rescue VoipappzClient::APIError => e
    Rails.logger.error("VoipAppz token verification failed: #{e.message}")
    raise AuthenticationError, "Authentication service unavailable"
  end

  # Build VoipAppz client for authentication requests
  def build_auth_client
    # Special auth client that doesn't require existing authentication
    VoipappzAuthClient.new
  end
end

# Specialized VoipAppz client for authentication requests
# Separate from main VoipappzClient to avoid circular dependencies
class VoipappzAuthClient
  include HTTParty
  base_uri ENV.fetch('VOIPAPPZ_AUTH_API_BASE_URL', 'https://auth.voipappz.io/v1')

  class AuthAPIError < StandardError; end
  class UnauthorizedError < AuthAPIError; end

  def initialize
    self.class.headers({
      'Content-Type' => 'application/json',
      'Accept' => 'application/json',
      'X-API-Key' => ENV.fetch('VOIPAPPZ_API_KEY', 'development_key')
    })
  end

  # Verify a user token with VoipAppz authentication service
  # @param token [String] JWT token to verify
  # @return [Hash] verification response with user data
  def verify_user_token(token)
    response = self.class.post('/auth/verify', {
      body: { token: token }.to_json
    })
    
    handle_auth_response(response)
  end

  # Get user details by user ID (for synchronization)
  # @param user_id [String] VoipAppz user ID
  # @return [Hash] user details
  def get_user_details(user_id)
    response = self.class.get("/users/#{user_id}")
    handle_auth_response(response)
  end

  # Get organization details by organization ID
  # @param org_id [String] VoipAppz organization ID
  # @return [Hash] organization details
  def get_organization_details(org_id)
    response = self.class.get("/organizations/#{org_id}")
    handle_auth_response(response)
  end

  private

  def handle_auth_response(response)
    case response.code
    when 200..299
      response.parsed_response
    when 401
      raise UnauthorizedError, "Invalid authentication"
    when 404
      nil
    else
      Rails.logger.error("VoipAppz Auth API error: #{response.code} - #{response.body}")
      raise AuthAPIError, "Authentication service error: #{response.code}"
    end
  rescue Net::TimeoutError, HTTParty::Error => e
    Rails.logger.error("VoipAppz Auth API request failed: #{e.message}")
    raise AuthAPIError, "Authentication service unavailable"
  end
end