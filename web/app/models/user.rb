# frozen_string_literal: true

class User < ApplicationRecord
  # VoipAppz platform user model
  # Authentication is handled by VoipAppz platform, not local Devise
  
  # Validations
  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :first_name, :last_name, presence: true, length: { maximum: 50 }
  validates :voipappz_user_id, presence: true, uniqueness: true
  validates :role, inclusion: { in: %w[owner admin agent user] }
  
  # Associations
  belongs_to :organization, optional: true
  has_many :created_items, class_name: 'Item', foreign_key: 'created_by_id', dependent: :nullify
  
  # Scopes
  scope :active, -> { where(active: true) }
  scope :by_role, ->(role) { where(role: role) }
  scope :with_permissions, ->(permission) { where('permissions ? ?', permission) }
  
  # JSON column for storing VoipAppz permissions
  serialize :permissions, JSON
  serialize :voipappz_metadata, JSON
  
  # Class methods
  class << self
    # Find user by VoipAppz user ID
    def find_by_voipappz_id(voipappz_user_id)
      find_by(voipappz_user_id: voipappz_user_id)
    end
    
    # Create user from VoipAppz platform data
    def create_from_voipappz(user_data)
      create!(
        voipappz_user_id: user_data[:user_id],
        email: user_data[:email],
        first_name: user_data[:first_name],
        last_name: user_data[:last_name],
        role: user_data[:role] || 'user',
        permissions: user_data[:permissions] || [],
        active: true,
        voipappz_metadata: {
          last_sync_at: Time.current.iso8601,
          organization_id: user_data[:organization_id],
          organization_name: user_data[:organization_name]
        }
      )
    end
  end
  
  # Instance methods
  def full_name
    "#{first_name} #{last_name}".strip
  end
  
  def display_name
    full_name.present? ? full_name : email
  end
  
  # Check if user has specific permission
  def has_permission?(permission)
    return true if role == 'owner' # Owner has all permissions
    return false unless permissions.is_a?(Array)
    
    permissions.include?(permission.to_s)
  end
  
  # Check if user can manage another user
  def can_manage_user?(other_user)
    return false if self == other_user # Can't manage yourself
    return true if role == 'owner' # Owner can manage everyone
    return false unless role == 'admin' # Only admin+ can manage
    
    # Admin can manage non-admin users
    !other_user.role.in?(%w[owner admin])
  end
  
  # Role hierarchy checks
  def owner?
    role == 'owner'
  end
  
  def admin?
    role.in?(%w[owner admin])
  end
  
  def agent?
    role.in?(%w[owner admin agent])
  end
  
  # Update user data from VoipAppz platform
  def sync_from_voipappz(user_data)
    update!(
      email: user_data[:email],
      first_name: user_data[:first_name],
      last_name: user_data[:last_name],
      role: user_data[:role] || role,
      permissions: user_data[:permissions] || permissions,
      active: user_data[:active] != false,
      voipappz_metadata: (voipappz_metadata || {}).merge({
        last_sync_at: Time.current.iso8601,
        organization_id: user_data[:organization_id],
        organization_name: user_data[:organization_name]
      })
    )
  end
  
  # Get user's VoipAppz metadata
  def voipappz_org_id
    voipappz_metadata&.dig('organization_id')
  end
  
  def last_sync_at
    return nil unless voipappz_metadata&.dig('last_sync_at')
    Time.parse(voipappz_metadata['last_sync_at'])
  rescue
    nil
  end
  
  # Check if user needs to be synced with VoipAppz
  def needs_sync?
    return true unless last_sync_at
    last_sync_at < 1.hour.ago
  end
  
  # Permission helpers for common CRM actions
  def can_view_calls?
    has_permission?('calls:read') || agent?
  end
  
  def can_manage_calls?
    has_permission?('calls:write') || admin?
  end
  
  def can_view_dashboard?
    has_permission?('dashboard:read') || agent?
  end
  
  def can_manage_users?
    has_permission?('users:manage') || admin?
  end
  
  def can_view_reports?
    has_permission?('reports:read') || agent?
  end
end
