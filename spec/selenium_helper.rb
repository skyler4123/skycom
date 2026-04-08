# frozen_string_literal: true

# This file configures Capybara to use a remote Selenium driver.
# Place this file in `spec/support/` and ensure it's loaded by your test runner.
# For RSpec, this is typically handled by `rails_helper.rb`.

require 'capybara/rails'
require 'capybara/rspec'
require 'selenium-webdriver'

TEST_RUN_INSIDE_DOCKER = ENV.fetch("TEST_RUN_INSIDE_DOCKER") { false }

if TEST_RUN_INSIDE_DOCKER
  Capybara.default_driver = :selenium_chrome_headless
  Capybara.javascript_driver = :selenium_chrome_headless  
else
  Capybara.default_driver = :selenium_chrome
  Capybara.javascript_driver = :selenium_chrome
end
