# frozen_string_literal: true

class DashboardController < AuthenticatedController
  def index
    # Use mediator pattern for orchestrating dashboard logic
    dashboard_data = Dashboard::Stats.run(
      organization: current_organization,
      user: current_user
    )
    
    # Extract data for view consumption
    @recent_calls = dashboard_data[:recent_calls]
    @todays_summary = dashboard_data[:todays_summary]
    @dashboard_stats = OpenStruct.new(dashboard_data[:live_metrics])
  end

  def live
    # Use mediator pattern for real-time dashboard data
    dashboard_data = Dashboard::Stats.run(
      organization: current_organization,
      user: current_user
    )
    
    # Extract live metrics for real-time view
    live_metrics = dashboard_data[:live_metrics]
    @active_calls = live_metrics[:active_calls]
    @total_calls_today = dashboard_data[:todays_summary][:total_calls]
    @agents_online = live_metrics[:agents_online]
    
    # Future: VoipAppz real-time data
    @voipappz_data = dashboard_data[:voipappz_data]
  end
end