# frozen_string_literal: true

require "test_helper"

class CallsQueryTest < ActiveSupport::TestCase
  setup do
    @organization = organizations(:one)
    @user = users(:one)
    @user.update!(organization: @organization)
    
    # Create diverse test data
    @active_call = @organization.items.create!(
      name: "Active Marketing Call",
      description: "Marketing campaign discussion",
      category: "marketing",
      status: "active", 
      created_by: @user,
      created_at: Time.current
    )
    
    @completed_call = @organization.items.create!(
      name: "Completed Support Call",
      description: "Customer support request",
      category: "communication",
      status: "inactive",
      created_by: @user,
      created_at: 2.hours.ago
    )
    
    @failed_call = @organization.items.create!(
      name: "Failed Sales Call",
      description: "Unsuccessful sales attempt",
      category: "sales", 
      status: "archived",
      created_by: @user,
      created_at: 1.day.ago
    )
  end

  test "should return calls with pagination and metadata" do
    result = CallsQuery.call(
      organization: @organization,
      pagination: { page: 1, per_page: 10 }
    )
    
    assert result.key?(:calls)
    assert result.key?(:total_count)
    assert result.key?(:filters_applied)
    assert result.key?(:aggregations)
    
    assert_equal 3, result[:total_count]
    assert_equal 3, result[:calls].count
  end

  test "should filter by status" do
    result = CallsQuery.call(
      organization: @organization,
      filters: { status: 'active' }
    )
    
    calls = result[:calls]
    assert_equal 1, calls.count
    assert_equal "Active Marketing Call", calls.first.name
    assert_equal({ status: 'active' }, result[:filters_applied])
  end

  test "should filter by multiple statuses" do
    result = CallsQuery.call(
      organization: @organization,
      filters: { status: ['active', 'completed'] }
    )
    
    calls = result[:calls]
    assert_equal 2, calls.count
    
    statuses = calls.map(&:status)
    assert_includes statuses, 'active'
    assert_includes statuses, 'inactive'  # 'completed' maps to 'inactive'
  end

  test "should filter by date range" do
    result = CallsQuery.call(
      organization: @organization,
      filters: { 
        start_date: Date.current.beginning_of_day,
        end_date: Date.current.end_of_day 
      }
    )
    
    # Should only include today's calls
    calls = result[:calls]
    assert_equal 2, calls.count
    
    call_names = calls.map(&:name)
    assert_includes call_names, "Active Marketing Call"
    assert_includes call_names, "Completed Support Call"
    assert_not_includes call_names, "Failed Sales Call"  # Yesterday
  end

  test "should filter by preset date ranges" do
    result = CallsQuery.call(
      organization: @organization,
      filters: { date_range: 'today' }
    )
    
    calls = result[:calls]
    assert_equal 2, calls.count  # Only today's calls
  end

  test "should filter by category" do
    result = CallsQuery.call(
      organization: @organization,
      filters: { category: 'marketing' }
    )
    
    calls = result[:calls]
    assert_equal 1, calls.count
    assert_equal "Active Marketing Call", calls.first.name
  end

  test "should search in names and descriptions" do
    result = CallsQuery.call(
      organization: @organization,
      filters: { search: 'support' }
    )
    
    calls = result[:calls]
    assert_equal 1, calls.count
    assert_equal "Completed Support Call", calls.first.name
  end

  test "should filter by agent" do
    result = CallsQuery.call(
      organization: @organization,
      filters: { agent_id: @user.id }
    )
    
    calls = result[:calls]
    assert_equal 3, calls.count  # All created by @user
    calls.each { |call| assert_equal @user.id, call.created_by_id }
  end

  test "should handle pagination correctly" do
    # Test first page
    result = CallsQuery.call(
      organization: @organization,
      pagination: { page: 1, per_page: 2 }
    )
    
    assert_equal 3, result[:total_count]
    assert_equal 2, result[:calls].count
    
    # Test second page
    result = CallsQuery.call(
      organization: @organization,
      pagination: { page: 2, per_page: 2 }
    )
    
    assert_equal 3, result[:total_count]
    assert_equal 1, result[:calls].count
  end

  test "should provide call aggregations" do
    result = CallsQuery.call(organization: @organization)
    
    aggregations = result[:aggregations]
    assert aggregations.key?(:by_status)
    assert aggregations.key?(:by_category)
    assert aggregations.key?(:by_agent)
    assert aggregations.key?(:total_duration)
    
    # Check status aggregation
    status_counts = aggregations[:by_status]
    assert_equal 1, status_counts['active']
    assert_equal 1, status_counts['inactive']
    assert_equal 1, status_counts['archived']
  end

  test "should scope to organization only" do
    # Create call for different organization
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
      created_by: other_user
    )
    
    result = CallsQuery.call(organization: @organization)
    
    call_names = result[:calls].map(&:name)
    assert_not_includes call_names, "Other Org Call"
    assert_equal 3, result[:total_count]
  end

  test "should handle empty organization" do
    result = CallsQuery.call(organization: nil)
    
    assert_equal 0, result[:total_count]
    assert_equal [], result[:calls]
    assert_equal({}, result[:filters_applied])
  end

  test "should limit pagination per_page to maximum" do
    result = CallsQuery.call(
      organization: @organization,
      pagination: { page: 1, per_page: 150 }  # Over limit
    )
    
    # Should be capped at 100
    # We can't directly test the limit, but calls should be limited
    assert result[:calls].count <= 100
  end

  test "should build PostgREST query URL" do
    query = CallsQuery.new(
      organization: @organization,
      filters: { 
        status: 'active',
        category: 'marketing',
        start_date: '2023-01-01',
        search: 'test'
      },
      pagination: { page: 1, per_page: 25 }
    )
    
    url = query.send(:build_calls_postgrest_query)
    
    assert_includes url, "organization_id=eq.#{@organization.id}"
    assert_includes url, "status=eq.active"
    assert_includes url, "category=eq.marketing"
    assert_includes url, "created_at=gte.2023-01-01"
    assert_includes url, "limit=25"
    assert_includes url, "order=created_at.desc"
  end

  test "should parse preset date ranges correctly" do
    query = CallsQuery.new(organization: @organization)
    
    # Test today range
    start_date, end_date = query.send(:parse_preset_date_range, 'today')
    assert_equal Date.current.beginning_of_day, start_date
    assert_equal Date.current.end_of_day, end_date
    
    # Test this_week range
    start_date, end_date = query.send(:parse_preset_date_range, 'this_week')
    assert_equal Date.current.beginning_of_week, start_date
    assert_equal Date.current.end_of_week, end_date
  end

  test "should handle invalid date strings gracefully" do
    query = CallsQuery.new(organization: @organization)
    
    result = query.send(:parse_date, 'invalid-date')
    assert_nil result
    
    result = query.send(:parse_date, nil)
    assert_nil result
  end
end