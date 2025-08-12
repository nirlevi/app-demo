# frozen_string_literal: true

# CallsQuery handles all call-related database queries for the CRM functionality
# This will be your primary interface for call data when integrating with VoipAppz platform
# Designed for PostgREST compatibility
class CallsQuery < ApplicationQuery
  def initialize(organization:, filters: {}, pagination: {})
    super
    @organization = organization
    @filters = filters.with_indifferent_access
    @pagination = pagination.with_indifferent_access
  end

  def call
    base_relation = build_filtered_calls_relation
    
    {
      calls: paginated_calls(base_relation),
      total_count: base_relation.count,
      filters_applied: active_filters_summary,
      aggregations: call_aggregations(base_relation)
    }
  end

  private

  attr_reader :organization, :filters, :pagination

  # Build the base relation with all filters applied
  def build_filtered_calls_relation
    relation = scope_to_organization(Item.all, organization)
    
    # Apply various filters
    relation = filter_by_status(relation)
    relation = filter_by_date_range_params(relation)
    relation = filter_by_category(relation)
    relation = filter_by_search_term(relation)
    relation = filter_by_agent(relation)
    
    # Default ordering
    relation.includes(:created_by).order(created_at: :desc)
  end

  # Apply status filter (active, completed, failed)
  def filter_by_status(relation)
    return relation unless filters[:status].present?
    
    case filters[:status]
    when 'active'
      relation.active
    when 'completed'
      relation.completed
    when 'failed'
      relation.failed
    when Array
      statuses = filters[:status].map do |status|
        case status
        when 'completed' then 'inactive'
        when 'failed' then 'archived'
        else status
        end
      end
      relation.where(status: statuses)
    else
      relation
    end
  end

  # Apply date range filter with flexible date parsing
  def filter_by_date_range_params(relation)
    start_date = parse_date(filters[:start_date])
    end_date = parse_date(filters[:end_date])
    
    # Handle preset date ranges
    if filters[:date_range].present?
      start_date, end_date = parse_preset_date_range(filters[:date_range])
    end
    
    filter_by_date_range(relation, :created_at, start_date, end_date)
  end

  # Filter by call category
  def filter_by_category(relation)
    return relation unless filters[:category].present?
    
    if filters[:category].is_a?(Array)
      relation.where(category: filters[:category])
    else
      relation.by_category(filters[:category])
    end
  end

  # Search in call names and descriptions
  def filter_by_search_term(relation)
    return relation unless filters[:search].present?
    
    relation.search(filters[:search])
  end

  # Filter by agent/created_by user
  def filter_by_agent(relation)
    return relation unless filters[:agent_id].present?
    
    relation.where(created_by_id: filters[:agent_id])
  end

  # Apply pagination to the relation
  def paginated_calls(relation)
    page = [pagination[:page].to_i, 1].max
    per_page = [pagination[:per_page].to_i, 25].max
    per_page = [per_page, 100].min # Max 100 per page
    
    offset = (page - 1) * per_page
    relation.limit(per_page).offset(offset)
  end

  # Parse date strings with error handling
  def parse_date(date_string)
    return nil unless date_string.present?
    Date.parse(date_string.to_s)
  rescue ArgumentError
    nil
  end

  # Handle preset date ranges like "today", "this_week", etc.
  def parse_preset_date_range(range)
    case range.to_s
    when 'today'
      [Date.current.beginning_of_day, Date.current.end_of_day]
    when 'yesterday'
      [1.day.ago.beginning_of_day, 1.day.ago.end_of_day]
    when 'this_week'
      [Date.current.beginning_of_week, Date.current.end_of_week]
    when 'last_week'
      [1.week.ago.beginning_of_week, 1.week.ago.end_of_week]
    when 'this_month'
      [Date.current.beginning_of_month, Date.current.end_of_month]
    when 'last_month'
      [1.month.ago.beginning_of_month, 1.month.ago.end_of_month]
    when 'last_30_days'
      [30.days.ago.beginning_of_day, Date.current.end_of_day]
    else
      [nil, nil]
    end
  end

  # Summary of applied filters for UI display
  def active_filters_summary
    summary = {}
    summary[:status] = filters[:status] if filters[:status].present?
    summary[:date_range] = filters[:date_range] if filters[:date_range].present?
    summary[:category] = filters[:category] if filters[:category].present?
    summary[:search] = filters[:search] if filters[:search].present?
    summary[:agent_id] = filters[:agent_id] if filters[:agent_id].present?
    summary
  end

  # Call aggregations for reporting
  def call_aggregations(relation)
    {
      by_status: relation.group(:status).count,
      by_category: relation.group(:category).count,
      by_agent: relation.joins(:created_by).group('users.first_name', 'users.last_name').count,
      by_hour: relation.group_by_hour(:created_at, range: 24.hours.ago..Time.current).count,
      total_duration: calculate_total_duration(relation) # Placeholder
    }
  end

  # Calculate total duration - placeholder for real duration data
  def calculate_total_duration(relation)
    # TODO: Replace with actual duration calculation when duration tracking is added
    call_count = relation.count
    estimated_total_seconds = call_count * 180 # Assume 3 minutes average
    
    hours = estimated_total_seconds / 3600
    minutes = (estimated_total_seconds % 3600) / 60
    
    "#{hours}h #{minutes}m"
  end

  # PostgREST query builder for calls
  # This will be used when migrating to PostgREST backend
  def build_calls_postgrest_query
    base_url = "/items"
    query_params = []
    
    # Organization filter
    query_params << "organization_id=eq.#{organization.id}"
    
    # Status filter
    if filters[:status].present?
      case filters[:status]
      when Array
        query_params << "status=in.(#{filters[:status].join(',')})"
      else
        query_params << "status=eq.#{filters[:status]}"
      end
    end
    
    # Date range filter
    if filters[:start_date].present?
      query_params << "created_at=gte.#{filters[:start_date]}"
    end
    
    if filters[:end_date].present?
      query_params << "created_at=lte.#{filters[:end_date]}"
    end
    
    # Category filter
    if filters[:category].present?
      query_params << "category=eq.#{filters[:category]}"
    end
    
    # Search filter (using PostgreSQL full-text search)
    if filters[:search].present?
      query_params << "or=(name.ilike.*#{filters[:search]}*,description.ilike.*#{filters[:search]}*)"
    end
    
    # Pagination
    if pagination[:page].present? && pagination[:per_page].present?
      page = [pagination[:page].to_i, 1].max
      per_page = [pagination[:per_page].to_i, 25].max
      offset = (page - 1) * per_page
      query_params << "offset=#{offset}"
      query_params << "limit=#{per_page}"
    end
    
    # Default ordering
    query_params << "order=created_at.desc"
    
    # Select specific columns
    query_params << "select=id,name,category,status,created_at,created_by_id,description"
    
    "#{base_url}?#{query_params.join('&')}"
  end
end