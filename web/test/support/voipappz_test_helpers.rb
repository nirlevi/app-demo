# frozen_string_literal: true

# Test helpers for VoipAppz integration testing
module VoipappzTestHelpers
  # Create a mock VoipAppz user data hash
  def mock_voipappz_user_data(overrides = {})
    {
      user_id: 'test_user_123',
      email: 'test@voipappz.io',
      first_name: 'Test',
      last_name: 'User',
      role: 'admin',
      organization_id: 'org_456',
      organization_name: 'Test Organization',
      permissions: ['calls:read', 'calls:write', 'dashboard:read'],
      active: true,
      exp: 1.day.from_now.to_i,
      iat: Time.current.to_i
    }.merge(overrides)
  end

  # Create a mock VoipAppz token for testing
  def create_test_voipappz_token(user_data = {})
    Rails.env.stubs(:development?).returns(true)
    ENV['VOIPAPPZ_USE_MOCK_AUTH'] = 'true'
    
    data = mock_voipappz_user_data(user_data)
    VoipappzAuthService.create_mock_token(data)
  ensure
    ENV.delete('VOIPAPPZ_USE_MOCK_AUTH')
  end

  # Mock VoipAppz API responses
  def mock_voipappz_api_success(endpoint, response_data = {})
    VoipappzClient.any_instance.stubs(endpoint).returns(response_data)
  end

  def mock_voipappz_api_error(endpoint, error_class = VoipappzClient::APIError)
    VoipappzClient.any_instance.stubs(endpoint).raises(error_class, "API Error")
  end

  # Create a user with VoipAppz authentication
  def create_voipappz_user(user_data = {})
    data = mock_voipappz_user_data(user_data)
    
    User.create!(
      voipappz_user_id: data[:user_id],
      email: data[:email],
      first_name: data[:first_name],
      last_name: data[:last_name],
      role: data[:role],
      permissions: data[:permissions],
      active: data[:active]
    )
  end

  # Create an organization with VoipAppz integration
  def create_voipappz_organization(org_data = {})
    defaults = {
      name: 'Test VoipAppz Org',
      slug: 'test-voipappz-org',
      plan: 'premium',
      voipappz_organization_id: 'voip_org_123',
      active: true
    }
    
    Organization.create!(defaults.merge(org_data))
  end

  # Mock successful authentication for controller tests
  def mock_voipappz_authentication(user_data = {})
    user = create_voipappz_user(user_data)
    organization = create_voipappz_organization
    user.update!(organization: organization)
    
    VoipappzAuthService.stubs(:verify_token).returns(mock_voipappz_user_data(user_data))
    
    # Set up the controller's current_user
    @controller.instance_variable_set(:@current_user, user)
    @controller.instance_variable_set(:@current_organization, organization)
    
    user
  end

  # Create test items for dashboard/calls testing
  def create_test_calls(organization, user, count = 3)
    statuses = ['active', 'inactive', 'archived']
    categories = ['communication', 'sales', 'marketing']
    
    count.times do |i|
      organization.items.create!(
        name: "Test Call #{i + 1}",
        description: "Test call description #{i + 1}",
        category: categories.sample,
        status: statuses.sample,
        created_by: user,
        created_at: Time.current - i.hours
      )
    end
  end

  # Mock WebMock for external API calls in integration tests
  def stub_voipappz_api_calls
    # Stub authentication endpoint
    stub_request(:post, "#{ENV.fetch('VOIPAPPZ_AUTH_API_BASE_URL', 'https://auth.voipappz.io/v1')}/auth/verify")
      .to_return(
        status: 200,
        body: {
          valid: true,
          user_data: mock_voipappz_user_data
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    # Stub live calls endpoint
    stub_request(:get, %r{#{ENV.fetch('VOIPAPPZ_API_BASE_URL', 'https://api.voipappz.io/v1')}/calls/live})
      .to_return(
        status: 200,
        body: {
          data: [
            {
              id: 'call_123',
              status: 'active',
              duration: 180,
              agent_id: 'agent_456'
            }
          ]
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    # Stub agents status endpoint
    stub_request(:get, %r{#{ENV.fetch('VOIPAPPZ_API_BASE_URL', 'https://api.voipappz.io/v1')}/agents/status})
      .to_return(
        status: 200,
        body: {
          agents: [
            {
              id: 'agent_456',
              status: 'available',
              name: 'Test Agent'
            }
          ]
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end
end

# Include in test case
ActiveSupport::TestCase.send(:include, VoipappzTestHelpers)