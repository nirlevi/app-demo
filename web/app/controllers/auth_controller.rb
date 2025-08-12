# frozen_string_literal: true

class AuthController < ApplicationController
  def login
    # Login form
    redirect_to dashboard_path if user_signed_in?
  end

  def logout
    sign_out current_user if user_signed_in?
    redirect_to login_path
  end
end