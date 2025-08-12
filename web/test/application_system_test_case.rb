# frozen_string_literal: true

require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :rack_test
  
  include Capybara::DSL
  include Capybara::Minitest::Assertions
end
