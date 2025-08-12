# frozen_string_literal: true

class SessionsController < Devise::SessionsController
  # GET /users/sign_in
  def new
    redirect_to login_path
  end

  # POST /users/sign_in
  def create
    self.resource = warden.authenticate(auth_options)
    if resource
      set_flash_message!(:notice, :signed_in)
      sign_in(resource_name, resource)
      yield resource if block_given?
      redirect_to dashboard_path
    else
      failure
    end
  end

  # DELETE /users/sign_out
  def destroy
    signed_out = (Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name))
    set_flash_message! :notice, :signed_out if signed_out
    yield if block_given?
    redirect_to login_path
  end

  private

  def auth_options
    { scope: resource_name, recall: "#{controller_path}#failure" }
  end

  def failure
    flash.now[:alert] = "Invalid email or password."
    self.resource = resource_class.new(sign_in_params)
    redirect_to login_path, alert: "Invalid email or password."
  end

  def sign_in_params
    params.require(:user).permit(:email, :password, :remember_me)
  end
end