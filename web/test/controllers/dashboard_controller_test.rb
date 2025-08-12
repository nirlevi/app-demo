# frozen_string_literal: true

require "test_helper"

class DashboardControllerTest < ActionController::TestCase
  setup do
    @organization = organizations(:one)
    @user = users(:one)
    @user.update!(organization: @organization)
    sign_in @user
  end

  test "should get index" do
    get :index
    assert_response :success
  end

  test "should get live with correct data" do
    # Create test items for this organization
    active_call = @organization.items.create!(
      name: "Active Call",
      category: "communication", 
      status: "active",
      created_by: @user
    )
    
    today_call = @organization.items.create!(
      name: "Today Call",
      category: "communication",
      status: "active", 
      created_by: @user,
      created_at: Time.current
    )

    get :live
    assert_response :success
    assert_match(/active calls/, response.body)
  end

  test "should calculate dashboard statistics" do
    # Create specific test data
    completed_call = @organization.items.create!(
      name: "Completed Call",
      category: "communication",
      status: "inactive",  # Maps to 'completed' via scope
      created_by: @user,
      created_at: Time.current
    )
    
    failed_call = @organization.items.create!(
      name: "Failed Call", 
      category: "communication",
      status: "archived",  # Maps to 'failed' via scope
      created_by: @user,
      created_at: Time.current
    )

    get :index
    assert_response :success
    
    # The controller should have calculated statistics
    # (We can't easily test assigns without additional gems, but response should work)
    assert_match(/Total Calls:/, response.body)
    assert_match(/Answered:/, response.body)
    assert_match(/Missed:/, response.body)
    
    # Test new enhanced statistics from service
    assert_match(/Average Duration:/, response.body)
    assert_match(/This Week:/, response.body)
    assert_match(/This Month:/, response.body)
    assert_match(/All Time:/, response.body)
    assert_match(/2:45/, response.body)  # Average duration from service
  end
end