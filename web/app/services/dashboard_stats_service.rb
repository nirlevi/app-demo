# frozen_string_literal: true

require 'ostruct'

class DashboardStatsService < ApplicationService
  attr_reader :organization

  def initialize(organization)
    super
    @organization = organization
  end

  def call
    OpenStruct.new(cached_dashboard_stats)
  end

  private

  def cached_dashboard_stats
    # Cache key includes organization ID and current date for cache invalidation
    cache_key = "dashboard_stats/#{organization&.id || 'no_org'}/#{Date.current}"
    
    Rails.cache.fetch(cache_key, expires_in: 5.minutes) do
      dashboard_stats
    end
  end

  def dashboard_stats
    # Use query object for all data retrieval
    query_result = DashboardStatsQuery.call(organization: organization)
    
    # Transform query result to maintain backward compatibility
    {
      # Recent activity
      recent_calls: query_result[:recent_calls],
      
      # Today's summary (flatten structure for backward compatibility)
      total_calls_today: query_result[:today_summary][:total_calls],
      answered_calls_today: query_result[:today_summary][:completed_calls],
      missed_calls_today: query_result[:today_summary][:failed_calls],
      
      # Live statistics
      active_calls: query_result[:live_metrics][:active_calls],
      agents_online: query_result[:user_metrics][:active_agents],
      
      # Calculated metrics
      average_duration: query_result[:live_metrics][:average_duration],
      
      # Enhanced metrics from query object
      total_calls_all_time: total_calls_calculation(query_result),
      calls_this_week: calls_this_week_calculation(query_result),
      calls_this_month: calls_this_month_calculation(query_result),
      calls_per_hour: query_result[:live_metrics][:calls_per_hour],
      
      # New analytics data
      time_series: query_result[:time_series],
      user_metrics: query_result[:user_metrics]
    }
  end

  # Calculate total calls from time series data or fallback
  def total_calls_calculation(query_result)
    # Use aggregated count from organization items
    organization&.items&.count || 0
  end

  # Extract this week's calls from time series data
  def calls_this_week_calculation(query_result)
    time_series = query_result[:time_series]
    return 0 unless time_series && time_series[:calls_this_week]
    
    time_series[:calls_this_week].values.sum
  end

  # Extract this month's calls from time series data
  def calls_this_month_calculation(query_result)
    time_series = query_result[:time_series]
    return 0 unless time_series && time_series[:calls_this_month]
    
    time_series[:calls_this_month].values.sum
  end
end