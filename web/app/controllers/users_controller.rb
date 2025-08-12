# frozen_string_literal: true

class UsersController < AuthenticatedController
  before_action :require_organization_admin, except: [:show]
  before_action :set_user, only: [:show, :update, :change_role, :toggle_active]

  def index
    @users = current_organization.users.includes(:organization)
    @users = @users.where('first_name ILIKE ? OR last_name ILIKE ? OR email ILIKE ?', 
                          "%#{params[:search]}%", "%#{params[:search]}%", "%#{params[:search]}%") if params[:search].present?
    @users = @users.where(role: params[:role]) if params[:role].present?
    @users = @users.where(active: params[:active]) if params[:active].present?
  end

  def show
    # Show individual user details
  end

  def update
    if @user.update(user_params)
      redirect_to @user, notice: 'User was successfully updated.'
    else
      render :show
    end
  end

  def change_role
    if @user.update(role: params[:role])
      redirect_to users_path, notice: 'User role updated successfully.'
    else
      redirect_to users_path, alert: 'Failed to update user role.'
    end
  end

  def toggle_active
    @user.update(active: !@user.active?)
    redirect_to users_path, notice: "User #{@user.active? ? 'activated' : 'deactivated'} successfully."
  end

  private

  def set_user
    @user = current_organization.users.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:first_name, :last_name, :email, :role, :active)
  end
end