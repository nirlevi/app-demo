# frozen_string_literal: true

class Api::ItemsController < Api::ApplicationController
  before_action :authenticate_user!
  before_action :set_item, only: [:show, :update, :destroy]

  # GET /api/items
  def index
    @items = organization_items
                                .limit(params[:per_page] || 25)
                                .offset(((params[:page] || 1).to_i - 1) * (params[:per_page] || 25).to_i)
    
    total_count = organization_items.count
    per_page = (params[:per_page] || 25).to_i
    current_page = (params[:page] || 1).to_i
    
    render json: {
      items: @items,
      pagination: {
        current_page: current_page,
        total_pages: (total_count.to_f / per_page).ceil,
        total_count: total_count,
        per_page: per_page
      }
    }
  end

  # GET /api/items/:id
  def show
    render json: { item: @item }
  end

  # POST /api/items
  def create
    @item = organization_items.build(item_params)
    @item.created_by = current_user
    
    if @item.save
      logger.info("Created item: #{@item.name} (ID: #{@item.id})")
      render json: { item: @item }, status: :created
    else
      render json: { 
        errors: @item.errors.full_messages 
      }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /api/items/:id
  def update
    if @item.update(item_params)
      logger.info("Updated item: #{@item.name} (ID: #{@item.id})")
      render json: { item: @item }
    else
      render json: { 
        errors: @item.errors.full_messages 
      }, status: :unprocessable_entity
    end
  end

  # DELETE /api/items/:id
  def destroy
    @item.destroy!
    logger.info("Deleted item: #{@item.name} (ID: #{@item.id})")
    render json: { success: true }
  rescue StandardError => e
    logger.error("Failed to delete item: #{e.message}")
    render json: { success: false, error: e.message }, status: :internal_server_error
  end

  # GET /api/items/count
  def count
    count = organization_items.count
    render json: { count: count }
  end

  private

  def set_item
    @item = organization_items.find(params[:id])
  end

  def item_params
    params.require(:item).permit(:name, :description, :category, :status, :metadata)
  end
end
