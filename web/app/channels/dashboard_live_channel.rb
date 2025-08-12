# frozen_string_literal: true

class DashboardLiveChannel < ApplicationCable::Channel
  def subscribed
    # Authenticate user first
    if current_user&.organization
      organization_id = current_user.organization.id
      stream_from "dashboard_live_#{organization_id}"
      logger.info "Subscribed to dashboard_live_#{organization_id}"
    else
      reject
      logger.error "DashboardLive subscription rejected: no authenticated user or organization"
    end
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
    logger.info "DashboardLive unsubscribed"
  end

  def refresh_data
    return unless current_user&.organization
    
    organization = current_user.organization
    
    # Get live dashboard data
    dashboard_data = {
      active_calls: organization.items.active.count,
      total_calls_today: organization.items.today.count,
      agents_online: organization.users.active.count,
      recent_calls: organization.items.recent.limit(5).map do |item|
        {
          id: item.id,
          time: item.created_at.strftime("%H:%M"),
          number: item.name,
          duration: item.description || "00:00",
          status: item.status || 'active',
          agent: item.user&.email || 'System'
        }
      end
    }
    
    # Broadcast to this organization's dashboard subscribers
    ActionCable.server.broadcast("dashboard_live_#{organization.id}", {
      type: 'dashboard_update',
      data: dashboard_data
    })
  end

  private

  def current_user
    # Get the current user from the connection
    connection.current_user if connection.respond_to?(:current_user)
  end
end