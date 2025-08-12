# frozen_string_literal: true

class ItemCreator < ApplicationService
  attr_reader :count, :organization, :user

  def initialize(count:, organization:, user:)
    super
    @count = count
    @organization = organization
    @user = user
  end

  def call
    created_items = []
    
    count.times do
      item = organization.items.create!(
        name: random_name,
        description: random_description,
        category: random_category,
        status: 'active',
        created_by: user
      )
      
      created_items << item
      Rails.logger.info("Created Item | Name: '#{item.name}' | Id: '#{item.id}' | Category: '#{item.category}'")
    end
    
    created_items
  end

  private

  def random_name
    "#{ADJECTIVES.sample} #{NOUNS.sample}".titleize
  end
  
  def random_description
    "A #{ADJECTIVES.sample} #{NOUNS.sample} that brings #{BENEFITS.sample} to your workflow."
  end
  
  def random_category
    CATEGORIES.sample
  end

  ADJECTIVES = [
    "smart", "efficient", "innovative", "reliable", "powerful",
    "elegant", "responsive", "intuitive", "seamless", "dynamic",
    "modern", "flexible", "robust", "secure", "scalable",
    "streamlined", "optimized", "enhanced", "advanced", "premium"
  ].freeze

  NOUNS = [
    "solution", "tool", "system", "platform", "service",
    "application", "framework", "widget", "component", "module",
    "dashboard", "interface", "workflow", "process", "method",
    "approach", "strategy", "technique", "mechanism", "feature"
  ].freeze
  
  BENEFITS = [
    "productivity", "efficiency", "clarity", "simplicity", "performance",
    "reliability", "security", "scalability", "flexibility", "innovation"
  ].freeze
  
  CATEGORIES = [
    "productivity", "communication", "analytics", "automation",
    "integration", "security", "development", "design", "marketing", "sales"
  ].freeze
end
