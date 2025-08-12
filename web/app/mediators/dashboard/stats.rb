# frozen_string_literal: true

module Dashboard
  # Dashboard::Stats mediator orchestrates dashboard data retrieval
  # and prepares for VoipAppz platform integration
  class Stats < ApplicationMediator
    def initialize(options = {})
      super
      @organization = options[:organization]
      @user = options[:user]
    end

    def call
      # Use query objects directly for better data layer separation
      dashboard_query_data = execute_query(DashboardStatsQuery, organization: @organization)
      
      # Get VoipAppz live data (when available)
      voipappz_live_data = fetch_voipappz_live_data
      
      # Combine internal CRM data with VoipAppz platform data
      enhance_stats_for_dashboard(dashboard_query_data, voipappz_live_data)
    end

    private

    attr_reader :organization, :user

    # Execute query objects with error handling
    # @param query_class [Class] the query class to execute
    # @param args [Hash] arguments to pass to query
    # @return [Hash] result from query execution
    def execute_query(query_class, **args)
      query_class.call(**args)
    rescue StandardError => e
      Rails.logger.error("Query execution failed: #{query_class} - #{e.message}")
      {} # Return empty hash to prevent errors
    end

    # Fetch live data from VoipAppz platform
    def fetch_voipappz_live_data
      return {} unless @organization # Ensure organization exists
      
      # Get live calls from VoipAppz platform
      live_calls = execute_voipappz_api(:get_live_calls, organization_id: @organization.id) || []
      agent_status = execute_voipappz_api(:get_agents_status, @organization.id) || []
      dashboard_metrics = execute_voipappz_api(:get_dashboard_metrics, @organization.id) || {}
      
      {
        live_calls: live_calls,
        agent_status: agent_status,
        real_time_metrics: dashboard_metrics,
        platform_connected: live_calls.present? || agent_status.present?
      }
    end

    # Enhance stats with additional business logic and VoipAppz data
    # @param query_data [Hash] data from DashboardStatsQuery
    # @param voipappz_data [Hash] data from VoipAppz platform
    # @return [Hash] enhanced stats ready for view consumption
    def enhance_stats_for_dashboard(query_data, voipappz_data)
      {
        # Internal CRM data from query objects
        recent_calls: query_data[:recent_calls] || [],
        todays_summary: build_enhanced_todays_summary(query_data, voipappz_data),
        live_metrics: build_enhanced_live_metrics(query_data, voipappz_data),
        
        # Analytics and time series data
        analytics: {
          time_series: query_data[:time_series] || {},
          user_metrics: query_data[:user_metrics] || {},
          call_trends: analyze_call_trends(query_data)
        },
        
        # VoipAppz platform data
        voipappz_data: voipappz_data.merge({
          integration_status: determine_integration_status(voipappz_data)
        })
      }
    end

    def build_enhanced_todays_summary(query_data, voipappz_data)
      today_summary = query_data[:today_summary] || {}
      
      # Combine internal data with VoipAppz real-time metrics
      platform_metrics = voipappz_data[:real_time_metrics] || {}
      
      {
        total_calls: today_summary[:total_calls] || 0,
        answered_calls: today_summary[:completed_calls] || 0,
        missed_calls: today_summary[:failed_calls] || 0,
        active_calls: today_summary[:active_calls] || 0,
        answer_rate: calculate_answer_rate(today_summary),
        
        # Enhanced metrics from VoipAppz (when available)
        platform_total_calls: platform_metrics[:total_calls_today],
        platform_answer_rate: platform_metrics[:answer_rate],
        average_wait_time: platform_metrics[:average_wait_time]
      }.compact
    end

    def build_enhanced_live_metrics(query_data, voipappz_data)
      live_metrics = query_data[:live_metrics] || {}
      user_metrics = query_data[:user_metrics] || {}
      
      {
        # Internal metrics
        active_calls: live_metrics[:active_calls] || 0,
        agents_online: user_metrics[:active_agents] || 0,
        average_duration: live_metrics[:average_duration] || "0:00",
        calls_per_hour: live_metrics[:calls_per_hour] || 0,
        
        # VoipAppz live metrics (when available)
        platform_active_calls: voipappz_data.dig(:real_time_metrics, :active_calls),
        platform_queue_length: voipappz_data.dig(:real_time_metrics, :queue_length),
        agents_status_breakdown: analyze_agent_status(voipappz_data[:agent_status])
      }.compact
    end

    def calculate_answer_rate(summary_data)
      total = summary_data[:total_calls] || 0
      answered = summary_data[:completed_calls] || 0
      
      return 0 if total.zero?
      ((answered.to_f / total) * 100).round(1)
    end

    def analyze_call_trends(query_data)
      time_series = query_data[:time_series] || {}
      
      {
        weekly_trend: calculate_trend(time_series[:calls_this_week]),
        monthly_trend: calculate_trend(time_series[:calls_this_month]),
        peak_hours: identify_peak_hours(time_series[:daily_breakdown])
      }
    end

    def calculate_trend(data_hash)
      return 0 unless data_hash.is_a?(Hash) && data_hash.size > 1
      
      values = data_hash.values
      return 0 if values.size < 2
      
      recent = values.last(3).sum.to_f / [values.last(3).size, 1].max
      earlier = values.first(3).sum.to_f / [values.first(3).size, 1].max
      
      return 0 if earlier.zero?
      ((recent - earlier) / earlier * 100).round(1)
    end

    def identify_peak_hours(daily_breakdown)
      return [] unless daily_breakdown.is_a?(Hash)
      
      # Group by hour and sum calls
      hourly_data = daily_breakdown.group_by { |key, _| Time.parse(key.to_s).hour rescue 0 }
                                  .transform_values { |entries| entries.sum { |_, count| count } }
      
      # Return top 3 peak hours
      hourly_data.sort_by { |_, count| -count }.first(3).map(&:first)
    rescue
      []
    end

    def analyze_agent_status(agent_status_data)
      return {} unless agent_status_data.is_a?(Array)
      
      agent_status_data.group_by { |agent| agent[:status] }
                      .transform_values(&:count)
    end

    def determine_integration_status(voipappz_data)
      if voipappz_data[:platform_connected]
        'connected'
      elsif voipappz_data.present?
        'partial'
      else
        'disconnected'
      end
    end
  end
end