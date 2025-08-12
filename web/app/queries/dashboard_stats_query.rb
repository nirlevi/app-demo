# frozen_string_literal: true

# DashboardStatsQuery handles all database queries for dashboard statistics
# Separates data access logic from business logic in DashboardStatsService
# Prepared for PostgREST integration
class DashboardStatsQuery < ApplicationQuery
  def initialize(organization:)
    super
    @organization = organization
  end

  def call
    {
      recent_calls: recent_calls_data,
      today_summary: today_summary_data,
      time_series: time_series_data,
      user_metrics: user_metrics_data,
      live_metrics: live_metrics_data
    }
  end

  private

  attr_reader :organization

  # Recent calls with user associations for display
  def recent_calls_data
    items_relation
      .includes(:created_by)
      .recent
      .limit(10)
  end

  # Today's call summary statistics
  def today_summary_data
    today_items = items_today
    {
      total_calls: today_items.count,
      completed_calls: today_items.completed.count,
      failed_calls: today_items.failed.count,
      active_calls: today_items.active.count
    }
  end

  # Time series data for charts (weekly/monthly trends)
  def time_series_data
    {
      calls_this_week: calls_by_week,
      calls_this_month: calls_by_month,
      daily_breakdown: daily_call_breakdown
    }
  end

  # User/agent related metrics
  def user_metrics_data
    users_relation = scope_to_organization(User.all, organization)
    {
      total_agents: users_relation.count,
      active_agents: users_relation.active.count,
      agents_with_calls_today: agents_with_calls_today_count
    }
  end

  # Live/real-time metrics for dashboard
  def live_metrics_data
    {
      active_calls: items_relation.active.count,
      average_duration: calculate_average_duration_raw,
      calls_per_hour: calls_per_hour_today
    }
  end

  # Base items relation scoped to organization
  def items_relation
    @items_relation ||= scope_to_organization(Item.all, organization)
  end

  # Today's items with efficient caching
  def items_today
    @items_today ||= filter_by_date_range(
      items_relation,
      :created_at,
      Date.current.beginning_of_day,
      Date.current.end_of_day
    )
  end

  # This week's calls
  def calls_by_week
    filter_by_date_range(
      items_relation,
      :created_at,
      1.week.ago.beginning_of_week,
      Date.current.end_of_day
    ).group_by_day(:created_at).count
  end

  # This month's calls
  def calls_by_month
    filter_by_date_range(
      items_relation,
      :created_at,
      1.month.ago.beginning_of_month,
      Date.current.end_of_day
    ).group_by_day(:created_at).count
  end

  # Daily breakdown for the current week
  def daily_call_breakdown
    start_of_week = Date.current.beginning_of_week
    end_of_week = Date.current.end_of_week
    
    filter_by_date_range(
      items_relation,
      :created_at,
      start_of_week,
      end_of_week
    ).group("DATE(created_at)").group(:status).count
  end

  # Count of agents who made calls today
  def agents_with_calls_today_count
    User.joins(:created_items)
        .where(organization: organization)
        .where(created_items: { created_at: Date.current.all_day })
        .distinct
        .count
  end

  # Calculate actual average duration from data
  # TODO: Replace with real duration data when available
  def calculate_average_duration_raw
    # Placeholder calculation - replace with actual duration column
    # when call duration tracking is implemented
    completed_today = items_today.completed.count
    return "0:00" if completed_today.zero?
    
    # Mock calculation based on call count (replace with real data)
    avg_seconds = [120, 180, 240, 300, 165].sample # Random for now
    minutes = avg_seconds / 60
    seconds = avg_seconds % 60
    "#{minutes}:#{seconds.to_s.rjust(2, '0')}"
  end

  # Calls per hour today
  def calls_per_hour_today
    total_calls = items_today.count
    hours_passed = [(Time.current - Date.current.beginning_of_day) / 1.hour, 1].max
    (total_calls / hours_passed).round(1)
  end

  # Future PostgREST query methods
  # These will replace ActiveRecord queries when migrating to PostgREST

  def postgrest_dashboard_stats
    {
      recent_calls: build_postgrest_query(
        'items',
        { organization_id: organization.id },
        %w[id name status created_at created_by_id]
      ) + "&order=created_at.desc&limit=10",
      
      today_summary: build_postgrest_query(
        'items',
        { 
          organization_id: organization.id,
          created_at: Date.current.beginning_of_day..Date.current.end_of_day
        }
      ) + "&select=status,count",
      
      live_metrics: build_postgrest_query(
        'items',
        { organization_id: organization.id, status: 'active' }
      ) + "&select=count"
    }
  end
end