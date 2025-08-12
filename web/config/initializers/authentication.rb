# frozen_string_literal: true

# VoipAppz Authentication Configuration
# This file configures JWT-based authentication for the VoipAppz mini app template

# Devise Configuration
Devise.setup do |config|
  config.mailer_sender = VoipappzConfig::SMTP_FROM_EMAIL
  
  # JWT configuration
  config.jwt do |jwt|
    jwt.secret = VoipappzConfig::JWT_SECRET
    jwt.dispatch_requests = [
      ['POST', %r{^/api/auth/sign_in$}],
      ['POST', %r{^/api/auth/sign_up$}]
    ]
    jwt.revocation_requests = [
      ['DELETE', %r{^/api/auth/sign_out$}]
    ]
    jwt.expiration_time = VoipappzConfig::JWT_EXPIRATION_HOURS.hours.to_i
  end
  
  # Configure password strength
  config.password_length = 8..128
  config.email_regexp = /\A[^@\s]+@[^@\s]+\z/
  
  # Security settings
  config.paranoid = true
  config.case_insensitive_keys = [:email]
  config.strip_whitespace_keys = [:email]
  config.skip_session_storage = [:http_auth, :token_auth]
end
