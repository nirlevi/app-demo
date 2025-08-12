# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # CSRF protection - disable for API controllers, enable for web controllers
  skip_before_action :verify_authenticity_token, if: -> { request.format.json? }
  
  # Include VoipAppz authentication
  include VoipappzAuthentication
  
  # Error handling
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
  rescue_from ActiveRecord::RecordInvalid, with: :record_invalid
  rescue_from ActionController::ParameterMissing, with: :parameter_missing
  
  protected
  
  private
  
  def record_not_found(exception)
    render json: { error: 'Record not found' }, status: :not_found
  end
  
  def record_invalid(exception)
    render json: { 
      error: 'Validation failed', 
      details: exception.record.errors.full_messages 
    }, status: :unprocessable_entity
  end
  
  def parameter_missing(exception)
    render json: { error: "Missing parameter: #{exception.param}" }, status: :bad_request
  end
  
  
  # Helper method for checking if current user can manage another user
  helper_method :can_manage_user?
  def can_manage_user?(user)
    return false unless current_user
    return false if current_user == user # Can't manage yourself
    return true if current_user.role == 'owner'
    return true if current_user.role == 'admin' && !%w[owner admin].include?(user.role)
    false
  end
  
  # Health check endpoint
  def health
    render json: {
      status: 'healthy',
      timestamp: Time.current.iso8601,
      version: '1.0.0',
      database: database_status
    }
  end
  
  private
  
  def database_status
    ActiveRecord::Base.connection.active? ? 'connected' : 'disconnected'
  rescue
    'error'
  end
end
