# frozen_string_literal: true

require "test_helper"

class ReportsControllerTest < ActionController::TestCase
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

  test "should get calls" do
    get :calls
    assert_response :success
  end
end