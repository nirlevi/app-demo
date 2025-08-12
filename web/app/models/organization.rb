# frozen_string_literal: true

class Organization < ApplicationRecord
  # Associations
  has_many :users, dependent: :destroy
  has_many :items, dependent: :destroy
  has_one :owner, -> { where(role: 'owner') }, class_name: 'User'
  
  # Validations
  validates :name, presence: true, length: { maximum: 100 }
  validates :slug, presence: true, uniqueness: { case_sensitive: false }, 
            format: { with: /\A[a-z0-9\-_]+\z/, message: "can only contain lowercase letters, numbers, hyphens, and underscores" }
  validates :plan, inclusion: { in: %w[free basic premium enterprise] }
  validates :voipappz_organization_id, uniqueness: { allow_nil: true }
  
  # Callbacks
  before_validation :generate_slug, if: -> { slug.blank? && name.present? }
  
  # Scopes
  scope :active, -> { where(active: true) }
  scope :by_plan, ->(plan) { where(plan: plan) }
  
  # Instance methods
  def display_name
    name
  end
  
  def free_plan?
    plan == 'free'
  end
  
  def premium_plan?
    %w[premium enterprise].include?(plan)
  end
  
  private
  
  def generate_slug
    base_slug = name.downcase.gsub(/[^a-z0-9\-_]/, '-').squeeze('-').strip('-')
    counter = 1
    potential_slug = base_slug
    
    while Organization.exists?(slug: potential_slug)
      potential_slug = "#{base_slug}-#{counter}"
      counter += 1
    end
    
    self.slug = potential_slug
  end
end
