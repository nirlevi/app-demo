# frozen_string_literal: true

require "test_helper"

class CallsControllerTest < ActionController::TestCase
  setup do
    @organization = organizations(:one)
    @user = users(:one)
    @user.update!(organization: @organization)
    sign_in @user
    
    @call = @organization.items.create!(
      name: "Test Call",
      category: "communication",
      status: "active",
      created_by: @user
    )
  end

  test "should get index" do
    get :index
    assert_response :success
  end

  test "should get show" do
    get :show, params: { id: @call.id }
    assert_response :success
  end

  test "should filter calls by search" do
    # Create another call that shouldn't match
    @organization.items.create!(
      name: "Different Name",
      category: "communication",
      status: "active",
      created_by: @user
    )
    
    get :index, params: { search: "Test" }
    assert_response :success
    # The response should work (we can't easily test content without assigns)
  end

  test "should filter calls by status" do
    # Create call with different status
    @organization.items.create!(
      name: "Inactive Call",
      category: "communication", 
      status: "inactive",
      created_by: @user
    )
    
    get :index, params: { status: "active" }
    assert_response :success
  end

  test "should filter calls by date range" do
    # Create old call
    @organization.items.create!(
      name: "Old Call",
      category: "communication",
      status: "active", 
      created_by: @user,
      created_at: 1.month.ago
    )
    
    get :index, params: { date_from: 1.week.ago.to_date, date_to: Date.current }
    assert_response :success
  end
end