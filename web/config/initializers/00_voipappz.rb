# frozen_string_literal: true

# VoipAppz Mini App Configuration
module VoipappzConfig
  # Application settings
  APP_NAME = ENV.fetch("APP_NAME", "VoipAppz Mini App")
  API_VERSION = "v1"
  
  # Authentication settings
  JWT_SECRET = ENV.fetch("JWT_SECRET") { Rails.application.secret_key_base }
  JWT_EXPIRATION_HOURS = ENV.fetch("JWT_EXPIRATION_HOURS", "24").to_i
  
  # Database settings
  DEFAULT_PAGE_SIZE = ENV.fetch("DEFAULT_PAGE_SIZE", "25").to_i
  MAX_PAGE_SIZE = ENV.fetch("MAX_PAGE_SIZE", "100").to_i
  
  # Feature flags
  ENABLE_API_DOCS = Rails.env.development? || ENV.fetch("ENABLE_API_DOCS", "false") == "true"
  ENABLE_BACKGROUND_JOBS = ENV.fetch("ENABLE_BACKGROUND_JOBS", "true") == "true"
  
  # External API settings (customize as needed)
  EXTERNAL_API_BASE_URL = ENV.fetch("EXTERNAL_API_BASE_URL", "")
  EXTERNAL_API_KEY = ENV.fetch("EXTERNAL_API_KEY", "")
  
  # Email settings
  SMTP_FROM_EMAIL = ENV.fetch("SMTP_FROM_EMAIL", "noreply@voipappz.com")
  
  class << self
    def configured?
      jwt_secret_present?
    end
    
    private
    
    def jwt_secret_present?
      JWT_SECRET.present?
    end
  end
end

# Validate configuration on startup
unless VoipappzConfig.configured?
  if defined? Rails::Server
    raise "Missing required environment variables. Check the README for setup instructions."
  end
end