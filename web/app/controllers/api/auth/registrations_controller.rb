# frozen_string_literal: true

class Api::Auth::RegistrationsController < Devise::RegistrationsController
  protect_from_forgery with: :null_session
  respond_to :json
  
  def create
    build_resource(sign_up_params)
    
    if resource.save
      sign_up(resource_name, resource)
      render json: {
        message: 'Account created successfully',
        user: {
          id: resource.id,
          email: resource.email,
          first_name: resource.first_name,
          last_name: resource.last_name,
          full_name: resource.full_name
        }
      }, status: :created
    else
      render json: {
        errors: resource.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  private

  def sign_up_params
    params.require(:user).permit(:email, :password, :password_confirmation, :first_name, :last_name)
  end
  
  def account_update_params
    params.require(:user).permit(:email, :password, :password_confirmation, :current_password, :first_name, :last_name)
  end
end