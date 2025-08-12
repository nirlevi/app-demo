# frozen_string_literal: true

class CallsController < AuthenticatedController
  def index
    filter_params = params.permit(:search, :status, :date_from, :date_to)
    @calls = ItemQuery.call(organization_items.includes(:created_by), filter_params)
    @calls = @calls.limit(25).offset((params[:page] || 1).to_i - 1) if params[:page]
    @total_count = @calls.count
  end

  def show
    @call = organization_items.find(params[:id])
  end

  def recordings
    @call = organization_items.find(params[:id])
    # Handle recording playback/download
  end

  private
end