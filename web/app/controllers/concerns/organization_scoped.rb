# frozen_string_literal: true

# OrganizationScoped provides common organization-scoped collection methods
# for controllers that need to access organization-specific data.
#
# Usage:
#   class MyController < AuthenticatedController
#     include OrganizationScoped
#     
#     def index
#       @items = scoped_items.recent
#       @users = scoped_users.active
#     end
#   end
module OrganizationScoped
  extend ActiveSupport::Concern
  
  private
  
  # Returns organization-scoped items collection
  # @return [ActiveRecord::Relation<Item>] scoped items or empty relation
  def scoped_items
    @scoped_items ||= current_organization&.items || Item.none
  end
  
  # Returns organization-scoped users collection  
  # @return [ActiveRecord::Relation<User>] scoped users or empty relation
  def scoped_users
    @scoped_users ||= current_organization&.users || User.none
  end
  
  # Alias methods for backward compatibility
  alias_method :organization_items, :scoped_items
  alias_method :organization_users, :scoped_users
end