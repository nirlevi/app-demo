# frozen_string_literal: true

class Api::UsersController < Api::ApplicationController
  before_action :authenticate_user!
  before_action :set_user, only: [:show, :update, :change_role, :toggle_active]
  
  def index
    @users = User.includes(:organization).active
    @users = @users.where(organization: current_user.organization) if current_user.organization
    
    render json: {
      users: @users.map do |user|
        {
          id: user.id,
          email: user.email,
          first_name: user.first_name,
          last_name: user.last_name,
          full_name: user.full_name,
          role: user.role,
          active: user.active,
          organization: user.organization&.name
        }
      end
    }
  end

  def show
    render json: {
      user: {
        id: @user.id,
        email: @user.email,
        first_name: @user.first_name,
        last_name: @user.last_name,
        full_name: @user.full_name,
        role: @user.role,
        active: @user.active,
        organization: @user.organization
      }
    }
  end

  def update
    if @user.update(user_params)
      render json: {
        message: 'User updated successfully',
        user: {
          id: @user.id,
          email: @user.email,
          first_name: @user.first_name,
          last_name: @user.last_name,
          full_name: @user.full_name
        }
      }
    else
      render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def change_role
    if @user.update(role: params[:role])
      render json: { message: 'User role updated successfully', role: @user.role }
    else
      render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def toggle_active
    @user.update!(active: !@user.active)
    render json: { 
      message: "User #{@user.active ? 'activated' : 'deactivated'} successfully",
      active: @user.active
    }
  end

  private

  def set_user
    @user = params[:id] == 'me' ? current_user : User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:first_name, :last_name, :email)
  end
end