# frozen_string_literal: true

require "test_helper"

class LoginTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @organization = organizations(:one)
  end

  test "successful login with valid credentials" do
    get login_path
    
    assert_response :success
    assert_select "h1", "VoipAppz"
    assert_select "h2", "Sign In"
    
    post user_session_path, params: {
      user: {
        email: @user.email,
        password: "password123"
      }
    }
    
    assert_redirected_to dashboard_path
    follow_redirect!
    assert_response :success
  end

  test "failed login with invalid email" do
    post user_session_path, params: {
      user: {
        email: "invalid@example.com",
        password: "password123"
      }
    }
    
    assert_redirected_to login_path
    follow_redirect!
    assert_response :success
  end

  test "failed login with invalid password" do
    post user_session_path, params: {
      user: {
        email: @user.email,
        password: "wrongpassword"
      }
    }
    
    assert_redirected_to login_path
    follow_redirect!
    assert_response :success
  end

  test "redirect to dashboard when already logged in" do
    # Log in user first
    post user_session_path, params: {
      user: {
        email: @user.email,
        password: "password123"
      }
    }
    
    # Try to visit login page again
    get login_path
    
    # Should be redirected to dashboard
    assert_redirected_to dashboard_path
  end

  test "login form elements are present" do
    get login_path
    
    assert_response :success
    assert_select "input[name='user[email]']"
    assert_select "input[name='user[password]']"
    assert_select "input[name='user[remember_me]']"
    assert_select "input[type='submit']"
    assert_select "a[href='#{new_user_password_path}']"
    assert_select "a[href='#{new_user_registration_path}']"
  end

  test "login page displays branding and features" do
    get login_path
    
    assert_response :success
    assert_select "h1", "VoipAppz"
    assert_select "p", "Professional Call Management Dashboard"
    assert_select "li", text: /Real-time call monitoring/
    assert_select "li", text: /Detailed reporting/
    assert_select "li", text: /Call recording management/
    assert_select "li", text: /Multi-user support/
  end

  test "successful logout" do
    # Log in first
    post user_session_path, params: {
      user: {
        email: @user.email,
        password: "password123"
      }
    }
    
    # Navigate to logout
    delete destroy_user_session_path
    
    assert_redirected_to login_path
    follow_redirect!
    assert_response :success
  end

  test "login form has proper accessibility attributes" do
    get login_path
    
    assert_response :success
    assert_select "label", text: "Email Address"
    assert_select "label", text: "Password"
    assert_select "label", text: "Remember me"
    assert_select "input[type='email']"
    assert_select "input[type='password']"
    assert_select "input[type='checkbox']"
  end
end