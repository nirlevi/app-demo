# frozen_string_literal: true

class Api::Auth::SessionsController < Devise::SessionsController
  protect_from_forgery with: :null_session
  respond_to :json
  
  def create
    self.resource = warden.authenticate!(auth_options)
    sign_in(resource_name, resource)
    
    render json: {
      message: 'Signed in successfully',
      user: {
        id: resource.id,
        email: resource.email,
        first_name: resource.first_name,
        last_name: resource.last_name,
        full_name: resource.full_name
      }
    }, status: :ok
  end

  def destroy
    if current_user
      sign_out(current_user)
      render json: { message: 'Signed out successfully' }, status: :ok
    else
      render json: { error: 'No active session found' }, status: :unauthorized
    end
  end

  def show
    if current_user
      render json: {
        user: {
          id: current_user.id,
          email: current_user.email,
          first_name: current_user.first_name,
          last_name: current_user.last_name,
          full_name: current_user.full_name,
          organization: current_user.organization
        }
      }
    else
      render json: { error: 'Not authenticated' }, status: :unauthorized
    end
  end

  private

  def auth_options
    { scope: resource_name, recall: "#{controller_path}#failure" }
  end

  def failure
    render json: { error: 'Invalid email or password' }, status: :unauthorized
  end
end