# frozen_string_literal: true

require "test_helper"

class Dashboard::StatsTest < ActiveSupport::TestCase
  setup do
    @organization = organizations(:one)
    @user = users(:one)
    @user.update!(organization: @organization)
    
    # Create test data
    @active_call = @organization.items.create!(
      name: "Active Call",
      category: "communication",
      status: "active",
      created_by: @user,
      created_at: Time.current
    )
    
    @completed_call = @organization.items.create!(
      name: "Completed Call", 
      category: "communication",
      status: "inactive",
      created_by: @user,
      created_at: Time.current
    )
  end

  test "should run mediator with valid organization and user" do
    result = Dashboard::Stats.run(organization: @organization, user: @user)
    
    assert_not_nil result
    assert result.key?(:recent_calls)
    assert result.key?(:todays_summary)
    assert result.key?(:live_metrics)
    assert result.key?(:analytics)
    assert result.key?(:voipappz_data)
  end

  test "should return empty data for nil organization" do
    result = Dashboard::Stats.run(organization: nil, user: @user)
    
    assert_equal [], result[:recent_calls]
    assert_equal 0, result[:todays_summary][:total_calls]
    assert_equal 0, result[:live_metrics][:active_calls]
  end

  test "should include recent calls in response" do
    result = Dashboard::Stats.run(organization: @organization, user: @user)
    
    recent_calls = result[:recent_calls]
    assert_includes recent_calls.map(&:name), "Active Call"
    assert_includes recent_calls.map(&:name), "Completed Call"
  end

  test "should calculate today's summary correctly" do
    result = Dashboard::Stats.run(organization: @organization, user: @user)
    
    summary = result[:todays_summary]
    assert_equal 2, summary[:total_calls]
    assert_equal 1, summary[:answered_calls]  # inactive status = completed
    assert_equal 0, summary[:missed_calls]    # no archived status
    assert_equal 1, summary[:active_calls]
  end

  test "should calculate answer rate correctly" do
    result = Dashboard::Stats.run(organization: @organization, user: @user)
    
    answer_rate = result[:todays_summary][:answer_rate]
    assert_equal 50.0, answer_rate  # 1 answered out of 2 total
  end

  test "should return zero answer rate for no calls" do
    # Clear all items
    @organization.items.destroy_all
    
    result = Dashboard::Stats.run(organization: @organization, user: @user)
    
    answer_rate = result[:todays_summary][:answer_rate]
    assert_equal 0, answer_rate
  end

  test "should include live metrics" do
    result = Dashboard::Stats.run(organization: @organization, user: @user)
    
    metrics = result[:live_metrics]
    assert_equal 1, metrics[:active_calls]
    assert_equal 1, metrics[:agents_online]  # one active user
    assert_not_nil metrics[:average_duration]
  end

  test "should handle VoipAppz API errors gracefully" do
    # Mock VoipAppz API failure
    mediator = Dashboard::Stats.new(organization: @organization, user: @user)
    mediator.stubs(:execute_voipappz_api).raises(StandardError, "API Error")
    
    result = mediator.call
    
    # Should still return valid data structure
    assert result.key?(:voipappz_data)
    assert_equal 'disconnected', result[:voipappz_data][:integration_status]
  end

  test "should include analytics data" do
    result = Dashboard::Stats.run(organization: @organization, user: @user)
    
    analytics = result[:analytics]
    assert analytics.key?(:time_series)
    assert analytics.key?(:user_metrics)
    assert analytics.key?(:call_trends)
  end

  test "should handle query execution errors" do
    # Mock query failure
    DashboardStatsQuery.stubs(:call).raises(StandardError, "Database error")
    
    result = Dashboard::Stats.run(organization: @organization, user: @user)
    
    # Should return empty data but not crash
    assert_equal [], result[:recent_calls]
    assert_not_nil result[:todays_summary]
  end

  test "should determine integration status correctly" do
    result = Dashboard::Stats.run(organization: @organization, user: @user)
    
    # Without VoipAppz data, should be disconnected
    assert_equal 'disconnected', result[:voipappz_data][:integration_status]
  end

  test "should analyze call trends when data available" do
    # Create calls over multiple days
    3.days.ago.to_date.upto(Date.current) do |date|
      @organization.items.create!(
        name: "Call on #{date}",
        category: "communication", 
        status: "inactive",
        created_by: @user,
        created_at: date.beginning_of_day + 10.hours
      )
    end
    
    result = Dashboard::Stats.run(organization: @organization, user: @user)
    
    trends = result[:analytics][:call_trends]
    assert trends.key?(:weekly_trend)
    assert trends.key?(:monthly_trend)
    assert trends.key?(:peak_hours)
  end
end