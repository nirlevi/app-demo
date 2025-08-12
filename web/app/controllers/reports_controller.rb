# frozen_string_literal: true

class ReportsController < AuthenticatedController
  def index
    @date_from = params[:date_from] || 1.month.ago.to_date
    @date_to = params[:date_to] || Date.current
    @items = organization_items
                        .where(created_at: @date_from..@date_to)
                        .includes(:created_by)
                        .limit(50)
  end

  def calls
    # Call history with filtering
    filter_params = params.permit(:search, :status, :date_from, :date_to)
    @calls = ItemQuery.call(organization_items, filter_params)
    @total_calls = @calls.count
    @selected_columns = params[:columns] || %w[date time duration status]
  end
end