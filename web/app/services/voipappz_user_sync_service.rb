# frozen_string_literal: true

# VoipAppz User Synchronization Service
# Handles creating and updating users based on VoipAppz platform data
class VoipappzUserSyncService < ApplicationService
  class SyncError < StandardError; end
  class OrganizationMismatchError < SyncError; end

  def initialize(user: nil, user_data:, organization: nil)
    super
    @user = user
    @user_data = user_data.with_indifferent_access
    @organization = organization
  end

  def call
    if @user
      update_existing_user
    else
      create_new_user
    end
  end

  class << self
    # Sync user from VoipAppz token data
    # @param user [User] existing user to update (optional)
    # @param user_data [Hash] user data from VoipAppz platform
    # @param organization [Organization] specific organization context (optional)
    # @return [User] synchronized user
    def sync_user(user: nil, user_data:, organization: nil)
      new(user: user, user_data: user_data, organization: organization).call
    end

    # Batch sync multiple users for an organization
    # @param users_data [Array<Hash>] array of user data from VoipAppz
    # @param organization [Organization] organization to sync users for
    # @return [Array<User>] array of synchronized users
    def batch_sync(users_data:, organization:)
      users_data.map do |user_data|
        existing_user = User.find_by_voipappz_id(user_data[:user_id])
        sync_user(user: existing_user, user_data: user_data, organization: organization)
      end
    end
  end

  private

  attr_reader :user, :user_data, :organization

  def update_existing_user
    Rails.logger.info("Syncing existing user: #{user.voipappz_user_id}")
    
    # Validate organization consistency
    validate_organization_consistency if organization
    
    # Update user with fresh data from VoipAppz
    user.sync_from_voipappz(user_data)
    
    # Sync organization if needed
    sync_user_organization
    
    Rails.logger.info("User sync completed: #{user.email}")
    user
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error("User sync failed: #{e.message}")
    raise SyncError, "Failed to update user: #{e.message}"
  end

  def create_new_user
    Rails.logger.info("Creating new user from VoipAppz: #{user_data[:email]}")
    
    # Find or create organization first
    user_organization = find_or_create_organization
    
    # Create user with VoipAppz data
    new_user = User.create_from_voipappz(user_data)
    new_user.update!(organization: user_organization) if user_organization
    
    Rails.logger.info("New user created: #{new_user.email}")
    new_user
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error("User creation failed: #{e.message}")
    raise SyncError, "Failed to create user: #{e.message}"
  end

  def sync_user_organization
    return unless user_data[:organization_id].present?
    
    # Find or create organization based on VoipAppz data
    user_organization = find_or_create_organization
    
    # Update user's organization if different
    if user.organization != user_organization
      Rails.logger.info("Updating user organization: #{user.email}")
      user.update!(organization: user_organization)
    end
  end

  def find_or_create_organization
    return organization if organization
    return nil unless user_data[:organization_id].present?
    
    # Try to find existing organization by VoipAppz ID
    org = Organization.find_by(voipappz_organization_id: user_data[:organization_id])
    
    unless org
      # Create organization from VoipAppz data
      org = create_organization_from_voipappz_data
    end
    
    org
  end

  def create_organization_from_voipappz_data
    Rails.logger.info("Creating organization from VoipAppz: #{user_data[:organization_name]}")
    
    Organization.create!(
      name: user_data[:organization_name],
      voipappz_organization_id: user_data[:organization_id],
      plan: determine_organization_plan,
      active: true
    )
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error("Organization creation failed: #{e.message}")
    # Return nil if organization creation fails - user will be created without org
    nil
  end

  def determine_organization_plan
    # Default plan based on user role or organization data
    case user_data[:role]
    when 'owner'
      'premium'
    when 'admin'
      'basic'
    else
      'free'
    end
  end

  def validate_organization_consistency
    return unless user.organization && organization
    
    if user.organization != organization
      raise OrganizationMismatchError, 
            "User belongs to different organization: #{user.organization.name} vs #{organization.name}"
    end
  end

  # Additional sync methods for advanced scenarios

  def sync_user_permissions
    return unless user_data[:permissions].present?
    
    permissions = normalize_permissions(user_data[:permissions])
    user.update!(permissions: permissions) if user.permissions != permissions
  end

  def normalize_permissions(raw_permissions)
    return [] unless raw_permissions.is_a?(Array)
    
    # Normalize permission strings to consistent format
    raw_permissions.map do |permission|
      permission.to_s.downcase.strip
    end.uniq.compact
  end

  def sync_user_profile_data
    # Sync additional profile data if available
    profile_data = user_data[:profile] || {}
    
    updates = {}
    updates[:phone] = profile_data[:phone] if profile_data[:phone].present?
    updates[:timezone] = profile_data[:timezone] if profile_data[:timezone].present?
    updates[:language] = profile_data[:language] if profile_data[:language].present?
    
    user.update!(updates) if updates.any?
  end

  def handle_user_deactivation
    # Handle user deactivation from VoipAppz platform
    if user_data[:active] == false && user.active?
      Rails.logger.info("Deactivating user: #{user.email}")
      user.update!(active: false)
      
      # Optional: Clear user sessions, disable access, etc.
      handle_user_session_cleanup
    elsif user_data[:active] != false && !user.active?
      Rails.logger.info("Reactivating user: #{user.email}")
      user.update!(active: true)
    end
  end

  def handle_user_session_cleanup
    # TODO: Implement session cleanup when user is deactivated
    # This could involve:
    # - Clearing cached tokens
    # - Notifying active sessions
    # - Logging security events
    Rails.logger.info("User session cleanup for: #{user.email}")
  end
end