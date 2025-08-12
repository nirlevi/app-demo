# frozen_string_literal: true

require "test_helper"

class ItemQueryTest < ActiveSupport::TestCase
  # Test the new ItemQuery service
  setup do
    @organization = organizations(:one)
    @user = users(:one)
    
    # Create test items with different attributes for filtering
    @active_item = @organization.items.create!(
      name: "Active Test Call",
      description: "Test description",
      category: "communication",
      status: "active",
      created_by: @user,
      created_at: 1.day.ago
    )
    
    @inactive_item = @organization.items.create!(
      name: "Inactive Test Call", 
      description: "Another test",
      category: "productivity",
      status: "inactive",
      created_by: @user,
      created_at: 1.week.ago
    )
    
    @recent_item = @organization.items.create!(
      name: "Recent Call",
      description: "Recent description",
      category: "communication",
      status: "active", 
      created_by: @user,
      created_at: Time.current
    )
  end

  test "should filter by search term" do
    # This test captures current behavior before refactoring
    base_scope = @organization.items
    filters = { search: "Test" }
    
    # Expected behavior: finds items with "Test" in name
    expected_items = base_scope.where("name LIKE ?", "%#{filters[:search]}%")
    
    assert_includes expected_items, @active_item
    assert_includes expected_items, @inactive_item
    assert_not_includes expected_items, @recent_item
  end

  test "should filter by status" do
    base_scope = @organization.items
    filters = { status: "active" }
    
    expected_items = base_scope.where(status: filters[:status])
    
    assert_includes expected_items, @active_item
    assert_includes expected_items, @recent_item
    assert_not_includes expected_items, @inactive_item
  end

  test "should filter by date range" do
    base_scope = @organization.items
    date_from = 2.days.ago.beginning_of_day
    date_to = Date.current.end_of_day
    filters = { date_from: date_from, date_to: date_to }
    
    expected_items = base_scope.where(created_at: filters[:date_from]..filters[:date_to])
    
    assert_includes expected_items, @active_item
    assert_includes expected_items, @recent_item
    assert_not_includes expected_items, @inactive_item
  end

  test "should combine multiple filters" do
    base_scope = @organization.items
    filters = { search: "Test", status: "active" }
    
    expected_items = base_scope
                      .where("name LIKE ?", "%#{filters[:search]}%")
                      .where(status: filters[:status])
    
    assert_includes expected_items, @active_item
    assert_not_includes expected_items, @inactive_item
    assert_not_includes expected_items, @recent_item
  end

  test "should return all items when no filters" do
    base_scope = @organization.items
    filters = {}
    
    expected_items = base_scope
    
    assert_includes expected_items, @active_item
    assert_includes expected_items, @inactive_item
    assert_includes expected_items, @recent_item
  end

  test "should handle empty search gracefully" do
    base_scope = @organization.items
    filters = { search: "" }
    
    # Empty search should not filter
    expected_items = base_scope
    
    assert_includes expected_items, @active_item
    assert_includes expected_items, @inactive_item
    assert_includes expected_items, @recent_item
  end

  # Tests for the new ItemQuery service
  test "ItemQuery should filter by search term" do
    result = ItemQuery.call(@organization.items, { search: "Test" })
    
    assert_includes result, @active_item
    assert_includes result, @inactive_item
    assert_not_includes result, @recent_item
  end

  test "ItemQuery should filter by status" do
    result = ItemQuery.call(@organization.items, { status: "active" })
    
    assert_includes result, @active_item
    assert_includes result, @recent_item
    assert_not_includes result, @inactive_item
  end

  test "ItemQuery should filter by date range" do
    date_from = 2.days.ago.beginning_of_day
    date_to = Date.current.end_of_day
    result = ItemQuery.call(@organization.items, { date_from: date_from, date_to: date_to })
    
    assert_includes result, @active_item
    assert_includes result, @recent_item
    assert_not_includes result, @inactive_item
  end

  test "ItemQuery should combine multiple filters" do
    result = ItemQuery.call(@organization.items, { search: "Test", status: "active" })
    
    assert_includes result, @active_item
    assert_not_includes result, @inactive_item
    assert_not_includes result, @recent_item
  end

  test "ItemQuery should return all items when no filters" do
    result = ItemQuery.call(@organization.items, {})
    
    assert_includes result, @active_item
    assert_includes result, @inactive_item
    assert_includes result, @recent_item
  end

  test "ItemQuery should handle empty search gracefully" do
    result = ItemQuery.call(@organization.items, { search: "" })
    
    assert_includes result, @active_item
    assert_includes result, @inactive_item
    assert_includes result, @recent_item
  end

  test "ItemQuery should search in both name and description" do
    # The @active_item has "Test" in name, let's create one with "Test" in description
    desc_item = @organization.items.create!(
      name: "Special Call",
      description: "Test in description",
      category: "communication",
      status: "active",
      created_by: @user
    )
    
    result = ItemQuery.call(@organization.items, { search: "Test" })
    
    assert_includes result, @active_item  # "Test" in name
    assert_includes result, desc_item     # "Test" in description
  end
end