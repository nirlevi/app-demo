# frozen_string_literal: true

# VoipAppz Authentication concern
# Replaces Devise authentication with VoipAppz platform authentication
module VoipappzAuthentication
  extend ActiveSupport::Concern

  included do
    # Set current user from VoipAppz token before each action
    before_action :authenticate_with_voipappz
    
    # Helper methods available in views
    helper_method :current_user, :user_signed_in?, :current_organization
    
    # Handle authentication errors
    rescue_from VoipappzAuthService::AuthenticationError, with: :handle_auth_error
    rescue_from VoipappzAuthService::InvalidTokenError, with: :handle_invalid_token
    rescue_from VoipappzAuthService::InsufficientPermissionsError, with: :handle_insufficient_permissions
  end

  private

  # Main authentication method - replaces Devise's authenticate_user!
  def authenticate_with_voipappz
    token = extract_token_from_request
    
    unless token
      return handle_missing_token
    end

    begin
      user_data = VoipappzAuthService.verify_token(token)
      @current_user = find_or_sync_user(user_data)
      @current_organization = @current_user.organization
      
      # Store token for API calls to VoipAppz
      @voipappz_token = token
      
    rescue VoipappzAuthService::InvalidTokenError
      handle_invalid_token
    rescue VoipappzAuthService::AuthenticationError => e
      handle_auth_error(e)
    end
  end

  # Extract JWT token from Authorization header or cookie
  def extract_token_from_request
    # Check Authorization header first (API requests)
    if request.headers['Authorization'].present?
      auth_header = request.headers['Authorization']
      return auth_header.gsub('Bearer ', '') if auth_header.start_with?('Bearer ')
    end
    
    # Check cookie for web requests
    cookies[:voipappz_token] ||
    # Check session as fallback
    session[:voipappz_token] ||
    # Check URL parameter for development
    params[:token]
  end

  # Find existing user or sync from VoipAppz platform
  def find_or_sync_user(user_data)
    user = User.find_by(voipappz_user_id: user_data[:user_id])
    
    if user
      # Update user data if needed
      VoipappzUserSyncService.call(user: user, user_data: user_data)
      user.reload
    else
      # Create new user from VoipAppz data
      VoipappzUserSyncService.call(user_data: user_data)
    end
  end

  # Check if user is authenticated
  def user_signed_in?
    current_user.present?
  end

  # Get current authenticated user
  def current_user
    @current_user
  end

  # Get current user's organization
  def current_organization
    @current_organization ||= current_user&.organization
  end

  # Get current VoipAppz token for API calls
  def voipappz_token
    @voipappz_token
  end

  # Require user to be authenticated
  def authenticate_user!
    return if user_signed_in?
    
    handle_unauthenticated
  end

  # Check if user has specific permission
  def require_permission(permission)
    return if current_user&.has_permission?(permission)
    
    raise VoipappzAuthService::InsufficientPermissionsError, 
          "Permission required: #{permission}"
  end

  # Require user to be organization owner
  def require_organization_owner
    require_permission('organization:admin')
  end

  # Require user to be organization admin or owner
  def require_organization_admin
    return if current_user&.role.in?(%w[owner admin])
    
    raise VoipappzAuthService::InsufficientPermissionsError, 
          "Admin access required"
  end

  # Error handlers

  def handle_missing_token
    if request.format.json?
      render json: { 
        error: 'Authentication required',
        message: 'VoipAppz token missing'
      }, status: :unauthorized
    else
      redirect_to_voipappz_login
    end
  end

  def handle_invalid_token(exception = nil)
    Rails.logger.warn("Invalid VoipAppz token: #{exception&.message}")
    
    # Clear invalid token
    cookies.delete(:voipappz_token)
    session.delete(:voipappz_token)
    
    if request.format.json?
      render json: { 
        error: 'Invalid authentication',
        message: 'Token expired or invalid'
      }, status: :unauthorized
    else
      flash[:alert] = 'Your session has expired. Please log in again.'
      redirect_to_voipappz_login
    end
  end

  def handle_auth_error(exception)
    Rails.logger.error("VoipAppz authentication error: #{exception.message}")
    
    if request.format.json?
      render json: { 
        error: 'Authentication service error',
        message: 'Please try again later'
      }, status: :service_unavailable
    else
      flash[:alert] = 'Authentication service temporarily unavailable.'
      redirect_to_voipappz_login
    end
  end

  def handle_insufficient_permissions(exception)
    Rails.logger.warn("Insufficient permissions: #{exception.message} for user #{current_user&.id}")
    
    if request.format.json?
      render json: { 
        error: 'Insufficient permissions',
        message: exception.message
      }, status: :forbidden
    else
      flash[:alert] = 'You do not have permission to access this resource.'
      redirect_to root_path
    end
  end

  def handle_unauthenticated
    if request.format.json?
      render json: { 
        error: 'Authentication required',
        message: 'Please authenticate with VoipAppz'
      }, status: :unauthorized
    else
      redirect_to_voipappz_login
    end
  end

  # Redirect to VoipAppz login page
  def redirect_to_voipappz_login
    login_url = build_voipappz_login_url
    redirect_to login_url, allow_other_host: true
  end

  # Build VoipAppz login URL with return path
  def build_voipappz_login_url
    base_url = ENV.fetch('VOIPAPPZ_LOGIN_URL', 'https://auth.voipappz.io/login')
    return_url = request.original_url
    app_id = ENV.fetch('VOIPAPPZ_APP_ID', 'crm_app')
    
    uri = URI(base_url)
    uri.query = URI.encode_www_form({
      return_url: return_url,
      app_id: app_id
    })
    
    uri.to_s
  end

  # Development helper - sign in with mock data
  def dev_sign_in_user(user_data = {})
    return unless Rails.env.development?
    
    token = VoipappzAuthService.create_mock_token(user_data)
    session[:voipappz_token] = token if token
    
    # Trigger authentication
    authenticate_with_voipappz
  end
end