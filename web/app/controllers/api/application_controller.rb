# frozen_string_literal: true

class Api::ApplicationController < ApplicationController
  protect_from_forgery with: :null_session
  before_action :authenticate_user!, except: [:health]
  
  # Health check endpoint
  def health
    render json: {
      status: 'healthy',
      timestamp: Time.current.iso8601,
      version: '1.0.0',
      database: database_status
    }
  end
  
  def current_organization
    @current_organization ||= current_user&.organization
  end
  
  # Organization-scoped collections helpers
  def organization_items
    @organization_items ||= current_organization&.items || Item.none
  end
  
  def organization_users
    @organization_users ||= current_organization&.users || User.none
  end
  
  private
  
  def database_status
    ActiveRecord::Base.connection.active? ? 'connected' : 'disconnected'
  rescue
    'error'
  end
end