# frozen_string_literal: true

class ItemQuery < ApplicationService
  attr_reader :scope, :filters

  def initialize(scope, filters = {})
    super
    @scope = scope
    @filters = filters.respond_to?(:to_h) ? filters.to_h.with_indifferent_access : filters.with_indifferent_access
  end

  def call
    result_scope = scope
    result_scope = apply_search(result_scope)
    result_scope = apply_status_filter(result_scope)
    result_scope = apply_date_range(result_scope)
    result_scope
  end

  private

  def apply_search(current_scope)
    return current_scope unless filters[:search].present?
    
    search_term = filters[:search].to_s.strip
    return current_scope if search_term.empty?
    
    current_scope.where("name LIKE ? OR description LIKE ?", 
                       "%#{search_term}%", "%#{search_term}%")
  end

  def apply_status_filter(current_scope)
    return current_scope unless filters[:status].present?
    
    current_scope.where(status: filters[:status])
  end

  def apply_date_range(current_scope)
    return current_scope unless filters[:date_from] && filters[:date_to]
    
    current_scope.where(created_at: filters[:date_from]..filters[:date_to])
  end
end