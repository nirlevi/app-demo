# frozen_string_literal: true

# VoipAppz API client for integrating with the VoipAppz platform
# Handles authentication and API communication following the platform's standards
class VoipappzClient
  include HTTParty
  
  # TODO: Configure with actual VoipAppz API base URL
  base_uri ENV.fetch('VOIPAPPZ_API_BASE_URL', 'https://api.voipappz.io/v1')
  
  # Custom exceptions for different API error types
  class APIError < StandardError; end
  class UnauthorizedError < APIError; end
  class NotFoundError < APIError; end
  class RateLimitError < APIError; end

  def initialize(organization_token:, user_token: nil)
    @organization_token = organization_token
    @user_token = user_token
    setup_headers
  end

  # Call Management API endpoints
  # These align with your requirement for VoipAppz platform VOIP functionality
  
  def get_live_calls(filters = {})
    get_request('/calls/live', filters)
  end

  def get_call_history(filters = {})
    get_request('/calls/history', filters)
  end

  def get_call_details(call_id)
    get_request("/calls/#{call_id}")
  end

  def get_call_recordings(call_id)
    get_request("/calls/#{call_id}/recordings")
  end

  # Agent/User Management
  def get_agents_status(organization_id = nil)
    filters = organization_id ? { organization_id: organization_id } : {}
    get_request('/agents/status', filters)
  end

  def get_agent_activity(agent_id, date_range = {})
    get_request("/agents/#{agent_id}/activity", date_range)
  end

  # Analytics & Reports (for your CRM functionality)
  def get_call_analytics(date_range = {})
    get_request('/analytics/calls', date_range)
  end

  def get_dashboard_metrics(organization_id = nil)
    filters = organization_id ? { organization_id: organization_id } : {}
    get_request('/analytics/dashboard', filters)
  end

  # Organization Management
  def get_organization_stats(organization_id)
    get_request("/organizations/#{organization_id}/stats")
  end

  private

  attr_reader :organization_token, :user_token

  def setup_headers
    headers = {
      'Content-Type' => 'application/json',
      'Accept' => 'application/json'
    }
    
    # Organization-level authentication
    headers['Authorization'] = "Bearer #{organization_token}" if organization_token
    
    # User-level authentication (when needed for user-specific operations)
    headers['X-User-Token'] = user_token if user_token
    
    self.class.headers(headers)
  end

  def get_request(endpoint, query = {})
    response = self.class.get(endpoint, query: query.compact)
    handle_response(response)
  rescue Net::TimeoutError, HTTParty::Error => e
    Rails.logger.error("VoipAppz API request failed: #{e.message}")
    raise APIError, "Request failed: #{e.message}"
  end

  def post_request(endpoint, body = {})
    response = self.class.post(endpoint, body: body.to_json)
    handle_response(response)
  rescue Net::TimeoutError, HTTParty::Error => e
    Rails.logger.error("VoipAppz API request failed: #{e.message}")
    raise APIError, "Request failed: #{e.message}"
  end

  def handle_response(response)
    Rails.logger.debug("VoipAppz API Response: #{response.code} - #{response.body}")
    
    case response.code
    when 200..299
      response.parsed_response
    when 401
      Rails.logger.error("VoipAppz API unauthorized: #{response.body}")
      raise UnauthorizedError, "Invalid authentication credentials"
    when 404
      raise NotFoundError, "Resource not found"
    when 429
      raise RateLimitError, "Rate limit exceeded"
    when 400..499
      error_message = parse_error_message(response)
      raise APIError, "Client error: #{error_message}"
    when 500..599
      Rails.logger.error("VoipAppz API server error: #{response.code} - #{response.body}")
      raise APIError, "Server error: #{response.code}"
    else
      raise APIError, "Unexpected response: #{response.code}"
    end
  end

  def parse_error_message(response)
    parsed = response.parsed_response
    if parsed.is_a?(Hash)
      parsed.dig('error', 'message') || parsed['message'] || "HTTP #{response.code}"
    else
      "HTTP #{response.code}"
    end
  rescue
    "HTTP #{response.code}"
  end
end