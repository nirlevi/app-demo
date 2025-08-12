# frozen_string_literal: true

require "test_helper"

class VoipappzAuthServiceTest < ActiveSupport::TestCase
  setup do
    @valid_user_data = {
      user_id: 'test_user_123',
      email: 'test@voipappz.io',
      first_name: 'Test',
      last_name: 'User',
      role: 'admin',
      organization_id: 'org_456',
      organization_name: 'Test Organization',
      permissions: ['calls:read', 'calls:write'],
      exp: 1.day.from_now.to_i,
      iat: Time.current.to_i
    }
  end

  test "should verify valid mock token in development" do
    Rails.env.stubs(:development?).returns(true)
    ENV['VOIPAPPZ_USE_MOCK_AUTH'] = 'true'
    
    token = VoipappzAuthService.create_mock_token(@valid_user_data)
    
    result = VoipappzAuthService.verify_token(token)
    
    assert_equal @valid_user_data[:user_id], result[:user_id]
    assert_equal @valid_user_data[:email], result[:email]
    assert_equal @valid_user_data[:role], result[:role]
  ensure
    ENV.delete('VOIPAPPZ_USE_MOCK_AUTH')
  end

  test "should create mock token with default values" do
    Rails.env.stubs(:development?).returns(true)
    
    token = VoipappzAuthService.create_mock_token
    
    assert_not_nil token
    
    # Decode to verify default values
    decoded = JSON.parse(Base64.strict_decode64(token))
    assert_equal 'test_user_123', decoded['user_id']
    assert_equal 'test@voipappz.io', decoded['email']
  end

  test "should not create mock token in production" do
    Rails.env.stubs(:production?).returns(true)
    Rails.env.stubs(:development?).returns(false)
    Rails.env.stubs(:test?).returns(false)
    
    token = VoipappzAuthService.create_mock_token
    
    assert_nil token
  end

  test "should raise InvalidTokenError for malformed token" do
    Rails.env.stubs(:development?).returns(true)
    ENV['VOIPAPPZ_USE_MOCK_AUTH'] = 'true'
    
    invalid_token = "invalid.token.here"
    
    assert_raises(VoipappzAuthService::InvalidTokenError) do
      VoipappzAuthService.verify_token(invalid_token)
    end
  ensure
    ENV.delete('VOIPAPPZ_USE_MOCK_AUTH')
  end

  test "should handle API verification in production mode" do
    Rails.env.stubs(:production?).returns(true)
    Rails.env.stubs(:development?).returns(false)
    Rails.env.stubs(:test?).returns(false)
    
    # Mock VoipappzAuthClient response
    VoipappzAuthClient.any_instance.stubs(:verify_user_token)
                     .returns({ valid: true, user_data: @valid_user_data })
    
    service = VoipappzAuthService.new(token: 'real_jwt_token')
    result = service.call
    
    assert_equal @valid_user_data[:user_id], result[:user_id]
    assert_equal @valid_user_data[:email], result[:email]
  end

  test "should raise InvalidTokenError for invalid API response" do
    Rails.env.stubs(:production?).returns(true)
    Rails.env.stubs(:development?).returns(false)
    Rails.env.stubs(:test?).returns(false)
    
    # Mock VoipappzAuthClient failure
    VoipappzAuthClient.any_instance.stubs(:verify_user_token)
                     .returns({ valid: false })
    
    service = VoipappzAuthService.new(token: 'invalid_token')
    
    assert_raises(VoipappzAuthService::InvalidTokenError) do
      service.call
    end
  end

  test "should raise AuthenticationError for API errors" do
    Rails.env.stubs(:production?).returns(true)
    Rails.env.stubs(:development?).returns(false)
    Rails.env.stubs(:test?).returns(false)
    
    # Mock VoipappzAuthClient API error
    VoipappzAuthClient.any_instance.stubs(:verify_user_token)
                     .raises(VoipappzClient::APIError, "Service unavailable")
    
    service = VoipappzAuthService.new(token: 'some_token')
    
    assert_raises(VoipappzAuthService::AuthenticationError) do
      service.call
    end
  end
end