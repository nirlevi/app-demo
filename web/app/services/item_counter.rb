# frozen_string_literal: true

class ItemCounter < ApplicationService
  attr_reader :organization, :filters

  def initialize(organization:, filters: {})
    super
    @organization = organization
    @filters = filters
  end

  def call
    # Use ItemQuery for standard filtering
    base_filters = filters.slice(:search, :status, :date_from, :date_to)
    scope = ItemQuery.call(organization.items, base_filters)
    
    # Apply ItemCounter-specific filters
    scope = scope.where(category: filters[:category]) if filters[:category].present?
    scope = scope.where('created_at >= ?', filters[:since]) if filters[:since].present?
    
    {
      total_count: scope.count,
      active_count: scope.where(status: 'active').count,
      inactive_count: scope.where(status: 'inactive').count,
      by_category: scope.group(:category).count,
      recent_count: scope.where('created_at >= ?', 7.days.ago).count
    }
  end
end
