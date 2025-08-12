# frozen_string_literal: true

# Configure AnyCable
AnyCable.configure do |config|
  # Redis configuration
  config.redis_url = ENV.fetch("REDIS_URL", "redis://localhost:6379/1")
  
  # RPC server configuration
  config.rpc_host = ENV.fetch("ANYCABLE_RPC_HOST", "localhost:50051")
  
  # Log configuration
  config.log_level = Rails.env.production? ? :info : :debug
  
  # Enable broadcasting
  config.broadcast_adapter = :redis
  
  # Configure persistent session
  config.persistent_session_enabled = true
end

# Configure Rails to use AnyCable
Rails.application.configure do
  # Set Action Cable adapter
  config.action_cable.adapter = :any_cable
  
  # Disable request forgery protection for development
  if Rails.env.development?
    config.action_cable.disable_request_forgery_protection = true
  end
end