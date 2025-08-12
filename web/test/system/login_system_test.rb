# frozen_string_literal: true

require "application_system_test_case"

class LoginSystemTest < ApplicationSystemTestCase
  setup do
    @user = users(:one)
    @organization = organizations(:one)
  end

  test "successful login flow" do
    visit login_path

    # Verify login page elements
    assert_text "VoipAppz"
    assert_text "Professional Call Management Dashboard"
    assert_text "Sign In"

    # Fill in login form
    fill_in "user[email]", with: @user.email
    fill_in "user[password]", with: "password123"
    
    # Submit the form
    click_button "Sign In"

    # Verify successful redirect to dashboard
    assert_current_path dashboard_path
    assert_text "Dashboard"
  end

  test "failed login shows error message" do
    visit login_path

    # Fill in form with invalid credentials
    fill_in "user[email]", with: "invalid@example.com"
    fill_in "user[password]", with: "wrongpassword"
    
    click_button "Sign In"

    # Should stay on login page and show error
    assert_current_path login_path
    assert_text "Invalid email or password."
  end

  test "login with remember me option" do
    visit login_path

    fill_in "user[email]", with: @user.email
    fill_in "user[password]", with: "password123"
    check "user[remember_me]"
    
    click_button "Sign In"

    # Verify successful redirect to dashboard
    assert_current_path dashboard_path
    assert_text "Dashboard"
  end

  test "login form has proper accessibility" do
    visit login_path

    # Check for proper labels
    assert_selector "label[for='user_email']", text: "Email Address"
    assert_selector "label[for='user_password']", text: "Password"
    assert_selector "label[for='user_remember_me']", text: "Remember me"
    
    # Check for proper input types
    assert_selector "input[type='email']"
    assert_selector "input[type='password']"
    assert_selector "input[type='checkbox']"
    
    # Check submit button
    assert_selector "input[type='submit']"
  end

  test "redirect to dashboard when already logged in" do
    # Log in first
    visit login_path
    fill_in "user[email]", with: @user.email
    fill_in "user[password]", with: "password123"
    click_button "Sign In"
    
    # Now try to visit login page again
    visit login_path
    
    # Should be redirected to dashboard
    assert_current_path dashboard_path
  end

  test "logout functionality" do
    # Log in first
    visit login_path
    fill_in "user[email]", with: @user.email
    fill_in "user[password]", with: "password123"
    click_button "Sign In"
    
    assert_current_path dashboard_path
    
    # Find and click logout link
    click_link "Logout"
    
    # Should be redirected to login page
    assert_current_path login_path
    assert_text "Sign In"
  end

  test "navigation links are present" do
    visit login_path

    # Check for forgot password and create account links
    assert_link "Forgot your password?"
    assert_link "Create an account"
  end

  test "branding and features are displayed" do
    visit login_path

    # Check branding
    assert_text "VoipAppz"
    assert_text "Professional Call Management Dashboard"
    
    # Check features list
    assert_text "Real-time call monitoring"
    assert_text "Detailed reporting" 
    assert_text "Call recording management"
    assert_text "Multi-user support"
  end

  test "form validation for empty fields" do
    visit login_path

    # Try to submit empty form
    click_button "Sign In"

    # Should still be on login page (HTML5 validation)
    assert_current_path login_path
  end
end