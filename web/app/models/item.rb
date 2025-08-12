# frozen_string_literal: true

class Item < ApplicationRecord
  # Associations
  belongs_to :organization
  belongs_to :created_by, class_name: 'User'
  alias_method :user, :created_by

  # Validations
  validates :name, presence: true, length: { maximum: 255 }
  validates :category, presence: true, inclusion: { 
    in: %w[productivity communication analytics automation integration security development design marketing sales] 
  }
  validates :status, inclusion: { in: %w[active inactive archived] }

  # Scopes
  scope :active, -> { where(status: 'active') }
  scope :inactive, -> { where(status: 'inactive') }
  scope :archived, -> { where(status: 'archived') }
  scope :by_category, ->(category) { where(category: category) }
  scope :recent, -> { order(created_at: :desc) }
  scope :today, -> { where('created_at >= ?', Date.current.beginning_of_day) }
  scope :search, ->(query) { where('name ILIKE ? OR description ILIKE ?', "%#{query}%", "%#{query}%") }
  
  # Call/Dashboard specific scopes (treating items as calls)
  scope :completed, -> { where(status: 'inactive') }
  scope :failed, -> { where(status: 'archived') }

  # Default pagination can be handled in controllers

  # Instance methods
  def active?
    status == 'active'
  end

  def inactive?
    status == 'inactive'
  end

  def archived?
    status == 'archived'
  end

  def display_name
    name
  end
end