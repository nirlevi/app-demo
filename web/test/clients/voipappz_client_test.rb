# frozen_string_literal: true

require "test_helper"

class VoipappzClientTest < ActiveSupport::TestCase
  setup do
    @organization_token = 'org_token_123'
    @user_token = 'user_token_456'
    @client = VoipappzClient.new(
      organization_token: @organization_token,
      user_token: @user_token
    )
    
    # Mock HTTP responses
    @successful_response = {
      'data' => [
        {
          'id' => 'call_123',
          'status' => 'active',
          'duration' => 180,
          'created_at' => Time.current.iso8601
        }
      ],
      'meta' => {
        'total' => 1
      }
    }
  end

  test "should initialize with organization and user tokens" do
    client = VoipappzClient.new(
      organization_token: @organization_token,
      user_token: @user_token
    )
    
    assert_equal @organization_token, client.instance_variable_get(:@organization_token)
    assert_equal @user_token, client.instance_variable_get(:@user_token)
  end

  test "should set correct headers on initialization" do
    expected_headers = {
      'Content-Type' => 'application/json',
      'Accept' => 'application/json',
      'Authorization' => "Bearer #{@organization_token}",
      'X-User-Token' => @user_token
    }
    
    # Check that headers are set correctly
    assert_equal expected_headers['Authorization'], 
                 VoipappzClient.headers['Authorization']
    assert_equal expected_headers['X-User-Token'], 
                 VoipappzClient.headers['X-User-Token']
  end

  test "should get live calls successfully" do
    VoipappzClient.expects(:get)
                  .with('/calls/live', query: {})
                  .returns(mock_response(200, @successful_response))
    
    result = @client.get_live_calls
    
    assert_equal @successful_response, result
  end

  test "should get live calls with filters" do
    filters = { status: 'active', agent_id: '123' }
    
    VoipappzClient.expects(:get)
                  .with('/calls/live', query: filters)
                  .returns(mock_response(200, @successful_response))
    
    result = @client.get_live_calls(filters)
    
    assert_equal @successful_response, result
  end

  test "should get call history" do
    VoipappzClient.expects(:get)
                  .with('/calls/history', query: {})
                  .returns(mock_response(200, @successful_response))
    
    result = @client.get_call_history
    
    assert_equal @successful_response, result
  end

  test "should get call details by ID" do
    call_id = 'call_123'
    
    VoipappzClient.expects(:get)
                  .with("/calls/#{call_id}")
                  .returns(mock_response(200, @successful_response['data'].first))
    
    result = @client.get_call_details(call_id)
    
    assert_equal @successful_response['data'].first, result
  end

  test "should get call recordings" do
    call_id = 'call_123'
    recordings_response = {
      'recordings' => [
        {
          'id' => 'rec_456',
          'url' => 'https://voipappz.io/recordings/rec_456.mp3',
          'duration' => 180
        }
      ]
    }
    
    VoipappzClient.expects(:get)
                  .with("/calls/#{call_id}/recordings")
                  .returns(mock_response(200, recordings_response))
    
    result = @client.get_call_recordings(call_id)
    
    assert_equal recordings_response, result
  end

  test "should get agents status" do
    VoipappzClient.expects(:get)
                  .with('/agents/status', query: {})
                  .returns(mock_response(200, { agents: [] }))
    
    result = @client.get_agents_status
    
    assert_equal({ agents: [] }, result)
  end

  test "should get agent activity" do
    agent_id = 'agent_789'
    date_range = { start_date: '2023-01-01', end_date: '2023-01-31' }
    
    VoipappzClient.expects(:get)
                  .with("/agents/#{agent_id}/activity", query: date_range)
                  .returns(mock_response(200, { activity: [] }))
    
    result = @client.get_agent_activity(agent_id, date_range)
    
    assert_equal({ activity: [] }, result)
  end

  test "should get call analytics" do
    VoipappzClient.expects(:get)
                  .with('/analytics/calls', query: {})
                  .returns(mock_response(200, { analytics: {} }))
    
    result = @client.get_call_analytics
    
    assert_equal({ analytics: {} }, result)
  end

  test "should get dashboard metrics" do
    org_id = 'org_123'
    
    VoipappzClient.expects(:get)
                  .with('/analytics/dashboard', 
                        query: { organization_id: org_id })
                  .returns(mock_response(200, { metrics: {} }))
    
    result = @client.get_dashboard_metrics(org_id)
    
    assert_equal({ metrics: {} }, result)
  end

  test "should get organization stats" do
    org_id = 'org_123'
    
    VoipappzClient.expects(:get)
                  .with("/organizations/#{org_id}/stats")
                  .returns(mock_response(200, { stats: {} }))
    
    result = @client.get_organization_stats(org_id)
    
    assert_equal({ stats: {} }, result)
  end

  test "should handle 401 unauthorized error" do
    VoipappzClient.expects(:get)
                  .returns(mock_response(401, { error: 'Unauthorized' }))
    
    assert_raises(VoipappzClient::UnauthorizedError) do
      @client.get_live_calls
    end
  end

  test "should handle 404 not found error" do
    VoipappzClient.expects(:get)
                  .returns(mock_response(404, { error: 'Not found' }))
    
    assert_raises(VoipappzClient::NotFoundError) do
      @client.get_call_details('nonexistent_call')
    end
  end

  test "should handle 429 rate limit error" do
    VoipappzClient.expects(:get)
                  .returns(mock_response(429, { error: 'Rate limit exceeded' }))
    
    assert_raises(VoipappzClient::RateLimitError) do
      @client.get_live_calls
    end
  end

  test "should handle generic API errors" do
    VoipappzClient.expects(:get)
                  .returns(mock_response(500, { error: 'Internal server error' }))
    
    error = assert_raises(VoipappzClient::APIError) do
      @client.get_live_calls
    end
    
    assert_includes error.message, "Server error: 500"
  end

  test "should handle network timeout errors" do
    VoipappzClient.expects(:get)
                  .raises(Net::TimeoutError, "Timeout")
    
    error = assert_raises(VoipappzClient::APIError) do
      @client.get_live_calls
    end
    
    assert_includes error.message, "Request failed: Timeout"
  end

  test "should handle HTTParty errors" do
    VoipappzClient.expects(:get)
                  .raises(HTTParty::Error, "Connection failed")
    
    error = assert_raises(VoipappzClient::APIError) do
      @client.get_live_calls
    end
    
    assert_includes error.message, "Request failed: Connection failed"
  end

  test "should parse error messages from response" do
    error_response = {
      'error' => {
        'message' => 'Invalid parameters'
      }
    }
    
    VoipappzClient.expects(:get)
                  .returns(mock_response(400, error_response))
    
    error = assert_raises(VoipappzClient::APIError) do
      @client.get_live_calls
    end
    
    assert_includes error.message, "Invalid parameters"
  end

  test "should handle responses without error message" do
    VoipappzClient.expects(:get)
                  .returns(mock_response(400, "Bad request"))
    
    error = assert_raises(VoipappzClient::APIError) do
      @client.get_live_calls
    end
    
    assert_includes error.message, "HTTP 400"
  end

  test "should log debug information on successful requests" do
    VoipappzClient.expects(:get)
                  .returns(mock_response(200, @successful_response))
    
    Rails.logger.expects(:debug).with(regexp_matches(/VoipAppz API Response: 200/))
    
    @client.get_live_calls
  end

  test "should log errors on failed requests" do
    VoipappzClient.expects(:get)
                  .returns(mock_response(401, { error: 'Unauthorized' }))
    
    Rails.logger.expects(:error).with(regexp_matches(/VoipAppz API unauthorized/))
    
    assert_raises(VoipappzClient::UnauthorizedError) do
      @client.get_live_calls
    end
  end

  private

  def mock_response(code, body)
    response = mock
    response.stubs(:code).returns(code)
    response.stubs(:body).returns(body.to_json)
    response.stubs(:parsed_response).returns(body)
    response
  end
end