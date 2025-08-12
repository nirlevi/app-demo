# frozen_string_literal: true

class AuthenticatedController < ApplicationController
  include OrganizationScoped
  
  # VoipAppz authentication is handled by ApplicationController
  before_action :authenticate_user!
  before_action :ensure_organization_exists
  
  protected
  
  def ensure_organization_exists
    return if current_organization
    
    if request.format.json?
      render json: { 
        error: 'Organization setup required',
        message: 'User must be associated with an organization'
      }, status: :unprocessable_entity
    else
      flash[:alert] = 'Organization setup required. Please contact support.'
      redirect_to root_path
    end
  end
  
  # Use VoipAppz permission system instead of simple role checks
  def require_organization_owner
    require_permission('organization:admin')
  end
  
  def require_organization_admin
    return if current_user&.admin?
    
    if request.format.json?
      render json: { error: 'Admin access required' }, status: :forbidden
    else
      flash[:alert] = 'Admin access required.'
      redirect_to root_path
    end
  end
end
