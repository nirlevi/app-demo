# frozen_string_literal: true

class Api::OrganizationsController < Api::ApplicationController
  before_action :authenticate_user!
  before_action :set_organization, only: [:show, :update, :stats]
  
  def show
    render json: {
      organization: {
        id: @organization.id,
        name: @organization.name,
        slug: @organization.slug,
        plan: @organization.plan,
        active: @organization.active,
        users_count: @organization.users.active.count,
        items_count: @organization.items.count,
        created_at: @organization.created_at,
        updated_at: @organization.updated_at
      }
    }
  end

  def update
    if @organization.update(organization_params)
      render json: {
        message: 'Organization updated successfully',
        organization: {
          id: @organization.id,
          name: @organization.name,
          slug: @organization.slug,
          plan: @organization.plan,
          active: @organization.active
        }
      }
    else
      render json: { errors: @organization.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def stats
    render json: {
      stats: {
        organization_name: @organization.name,
        total_users: @organization.users.count,
        active_users: @organization.users.active.count,
        total_items: @organization.items.count,
        items_by_status: @organization.items.group(:status).count,
        items_by_category: @organization.items.group(:category).count,
        recent_activity: {
          items_created_this_week: @organization.items.where('created_at >= ?', 1.week.ago).count,
          items_created_this_month: @organization.items.where('created_at >= ?', 1.month.ago).count
        }
      }
    }
  end

  private

  def set_organization
    @organization = current_user.organization || current_user.build_organization
  end

  def organization_params
    params.require(:organization).permit(:name, :plan)
  end
end