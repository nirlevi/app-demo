# frozen_string_literal: true

require "test_helper"

class DashboardStatsQueryTest < ActiveSupport::TestCase
  setup do
    @organization = organizations(:one)
    @user = users(:one)
    @user.update!(organization: @organization, active: true)
    
    # Create test items for different time periods and statuses
    @today_active = @organization.items.create!(
      name: "Today Active Call",
      category: "communication",
      status: "active",
      created_by: @user,
      created_at: Time.current
    )
    
    @today_completed = @organization.items.create!(
      name: "Today Completed Call",
      category: "communication", 
      status: "inactive",
      created_by: @user,
      created_at: Time.current
    )
    
    @yesterday_call = @organization.items.create!(
      name: "Yesterday Call",
      category: "communication",
      status: "inactive", 
      created_by: @user,
      created_at: 1.day.ago
    )
    
    @last_week_call = @organization.items.create!(
      name: "Last Week Call",
      category: "analytics",
      status: "archived",
      created_by: @user,
      created_at: 1.week.ago
    )
  end

  test "should return all required data sections" do
    result = DashboardStatsQuery.call(organization: @organization)
    
    assert result.key?(:recent_calls)
    assert result.key?(:today_summary)
    assert result.key?(:time_series)
    assert result.key?(:user_metrics)
    assert result.key?(:live_metrics)
  end

  test "should return recent calls with user associations" do
    result = DashboardStatsQuery.call(organization: @organization)
    
    recent_calls = result[:recent_calls]
    assert_equal 4, recent_calls.count
    assert recent_calls.first.created_by.present?
  end

  test "should calculate today summary correctly" do
    result = DashboardStatsQuery.call(organization: @organization)
    
    summary = result[:today_summary]
    assert_equal 2, summary[:total_calls]     # 2 calls today
    assert_equal 1, summary[:completed_calls] # 1 inactive (completed) today
    assert_equal 0, summary[:failed_calls]    # 0 archived (failed) today
    assert_equal 1, summary[:active_calls]    # 1 active today
  end

  test "should return empty summary for organization with no calls" do
    empty_org = organizations(:two)
    
    result = DashboardStatsQuery.call(organization: empty_org)
    
    summary = result[:today_summary]
    assert_equal 0, summary[:total_calls]
    assert_equal 0, summary[:completed_calls]
    assert_equal 0, summary[:failed_calls]
    assert_equal 0, summary[:active_calls]
  end

  test "should include time series data" do
    result = DashboardStatsQuery.call(organization: @organization)
    
    time_series = result[:time_series]
    assert time_series.key?(:calls_this_week)
    assert time_series.key?(:calls_this_month)
    assert time_series.key?(:daily_breakdown)
    
    # Should be Hash with date keys
    assert time_series[:calls_this_week].is_a?(Hash)
    assert time_series[:calls_this_month].is_a?(Hash)
  end

  test "should calculate user metrics" do
    result = DashboardStatsQuery.call(organization: @organization)
    
    user_metrics = result[:user_metrics]
    assert_equal 1, user_metrics[:total_agents]
    assert_equal 1, user_metrics[:active_agents]
    assert user_metrics[:agents_with_calls_today] >= 0
  end

  test "should calculate live metrics" do
    result = DashboardStatsQuery.call(organization: @organization)
    
    live_metrics = result[:live_metrics]
    assert_equal 1, live_metrics[:active_calls]
    assert_not_nil live_metrics[:average_duration]
    assert live_metrics[:calls_per_hour] >= 0
  end

  test "should handle nil organization gracefully" do
    result = DashboardStatsQuery.call(organization: nil)
    
    assert_equal [], result[:recent_calls]
    assert_equal 0, result[:today_summary][:total_calls]
    assert_equal 0, result[:live_metrics][:active_calls]
  end

  test "should scope data to organization only" do
    # Create items for different organization
    other_org = organizations(:two)
    other_user = User.create!(
      voipappz_user_id: 'other_user',
      email: 'other@test.com',
      first_name: 'Other',
      last_name: 'User',
      organization: other_org,
      role: 'user'
    )
    
    other_org.items.create!(
      name: "Other Org Call",
      category: "communication",
      status: "active",
      created_by: other_user,
      created_at: Time.current
    )
    
    result = DashboardStatsQuery.call(organization: @organization)
    
    # Should not include other organization's data
    call_names = result[:recent_calls].map(&:name)
    assert_not_includes call_names, "Other Org Call"
  end

  test "should build PostgREST query structure" do
    query = DashboardStatsQuery.new(organization: @organization)
    
    # Test the PostgREST query building method exists
    assert_respond_to query, :postgrest_dashboard_stats
    
    postgrest_queries = query.send(:postgrest_dashboard_stats)
    assert postgrest_queries.key?(:recent_calls)
    assert postgrest_queries.key?(:today_summary)
    assert postgrest_queries.key?(:live_metrics)
  end

  test "should calculate calls per hour correctly" do
    # Create multiple calls today
    5.times do |i|
      @organization.items.create!(
        name: "Call #{i}",
        category: "communication",
        status: "active",
        created_by: @user,
        created_at: Time.current - i.hours
      )
    end
    
    result = DashboardStatsQuery.call(organization: @organization)
    
    calls_per_hour = result[:live_metrics][:calls_per_hour]
    assert calls_per_hour > 0
    assert calls_per_hour.is_a?(Float)
  end

  test "should generate valid average duration" do
    result = DashboardStatsQuery.call(organization: @organization)
    
    duration = result[:live_metrics][:average_duration]
    assert_match(/\A\d+:\d{2}\z/, duration)  # Format: "MM:SS"
  end
end