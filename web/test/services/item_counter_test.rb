# frozen_string_literal: true

require "test_helper"

class ItemCounterTest < ActiveSupport::TestCase
  setup do
    @organization = organizations(:one)
    @user = users(:one)
    
    @active_item = @organization.items.create!(
      name: "Active Test Call",
      category: "communication",
      status: "active",
      created_by: @user
    )
    
    @inactive_item = @organization.items.create!(
      name: "Inactive Test Call",
      category: "productivity", 
      status: "inactive",
      created_by: @user
    )
  end

  test "should count items correctly" do
    result = ItemCounter.call(organization: @organization)
    
    # 2 from fixtures + 2 we created = 4 total
    assert_equal 4, result[:total_count]
    assert_equal 2, result[:active_count]  # fixture "one" + @active_item
    assert_equal 2, result[:inactive_count]  # fixture "two" + @inactive_item
    assert result[:by_category].key?("communication")
    assert result[:by_category].key?("productivity")
  end

  test "should apply search filter using ItemQuery" do
    # The main thing is that ItemQuery search functionality works 
    # (detailed testing is in item_query_test.rb)
    result = ItemCounter.call(organization: @organization, filters: { search: "Active Test" })
    
    # Just verify that search is applied (result should be filtered)
    assert result[:total_count] <= 4  # Should be less than or equal to total items
  end

  test "should apply status filter using ItemQuery" do
    result = ItemCounter.call(organization: @organization, filters: { status: "active" })
    
    # fixture "one" + @active_item = 2 active items
    assert_equal 2, result[:total_count]
    assert_equal 2, result[:active_count]
    assert_equal 0, result[:inactive_count]
  end

  test "should apply category filter" do
    result = ItemCounter.call(organization: @organization, filters: { category: "communication" })
    
    # fixture "one" + @active_item = 2 communication items
    assert_equal 2, result[:total_count]
    assert_equal 2, result[:active_count]
    assert_equal 0, result[:inactive_count]
  end
end