# frozen_string_literal: true

# ApplicationQuery provides the foundation for the Query Object pattern
# Designed to prepare for PostgREST integration and clean data layer separation
class ApplicationQuery
  class << self
    # Query objects follow service pattern for consistency
    # @param options [Hash] options to pass to the query
    # @return [Object] result from the query's call method
    def call(*args, **kwargs)
      new(*args, **kwargs).call
    end
  end

  # @param options [Hash] initialization options
  def initialize(**options)
    @options = options
  end

  # Abstract method to be implemented by subclasses
  # @raise [NotImplementedError] if not implemented by subclass
  def call
    raise NotImplementedError, "#{self.class} must implement #call"
  end

  private

  attr_reader :options

  # Helper method for building ActiveRecord scopes
  # This will be useful when transitioning to PostgREST
  # @param model_class [Class] the ActiveRecord model class
  # @param scopes [Array<Hash>] array of scope configurations
  # @return [ActiveRecord::Relation] the scoped relation
  def build_scoped_relation(model_class, scopes = [])
    relation = model_class.all
    
    scopes.each do |scope_config|
      case scope_config[:type]
      when :method
        relation = relation.public_send(scope_config[:method], *scope_config[:args] || [])
      when :where
        relation = relation.where(scope_config[:conditions])
      when :joins
        relation = relation.joins(scope_config[:associations])
      when :includes
        relation = relation.includes(scope_config[:associations])
      when :order
        relation = relation.order(scope_config[:columns])
      when :limit
        relation = relation.limit(scope_config[:count])
      end
    end
    
    relation
  end

  # Helper for date range filtering - common pattern for analytics
  # @param relation [ActiveRecord::Relation] the base relation
  # @param date_column [Symbol] the date column to filter on
  # @param start_date [Date, Time] start of date range
  # @param end_date [Date, Time] end of date range
  # @return [ActiveRecord::Relation] filtered relation
  def filter_by_date_range(relation, date_column, start_date = nil, end_date = nil)
    return relation unless start_date || end_date

    if start_date && end_date
      relation.where(date_column => start_date..end_date)
    elsif start_date
      relation.where("#{date_column} >= ?", start_date)
    elsif end_date
      relation.where("#{date_column} <= ?", end_date)
    else
      relation
    end
  end

  # Helper for organization scoping - essential for multi-tenant CRM
  # @param relation [ActiveRecord::Relation] the base relation
  # @param organization [Organization] the organization to scope to
  # @return [ActiveRecord::Relation] organization-scoped relation
  def scope_to_organization(relation, organization)
    return relation.none unless organization
    relation.where(organization: organization)
  end

  # Future: PostgREST query builder
  # This will be used when transitioning to PostgREST API backend
  # @param table [String] PostgreSQL table name
  # @param filters [Hash] filter conditions
  # @param select_columns [Array] columns to select
  # @return [String] PostgREST query URL fragment
  def build_postgrest_query(table, filters = {}, select_columns = [])
    query_params = []
    
    # Select specific columns
    query_params << "select=#{select_columns.join(',')}" if select_columns.any?
    
    # Add filters
    filters.each do |column, value|
      case value
      when Array
        query_params << "#{column}=in.(#{value.join(',')})"
      when Range
        query_params << "#{column}=gte.#{value.begin}&#{column}=lte.#{value.end}"
      else
        query_params << "#{column}=eq.#{value}"
      end
    end
    
    "/#{table}#{query_params.any? ? '?' + query_params.join('&') : ''}"
  end
end