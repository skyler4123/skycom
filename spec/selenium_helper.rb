# frozen_string_literal: true

# This file configures Capybara to use a remote Selenium driver.
# Place this file in `spec/support/` and ensure it's loaded by your test runner.
# For RSpec, this is typically handled by `rails_helper.rb`.

require 'capybara/rails'
require 'capybara/rspec'
require 'selenium-webdriver'

TEST_RUN_INSIDE_DOCKER = ENV.fetch("TEST_RUN_INSIDE_DOCKER") { false }

if TEST_RUN_INSIDE_DOCKER
  Capybara.register_driver :selenium_chrome_docker do |app|
    options = Selenium::WebDriver::Options.chrome(
      args: [
        "--headless=new",         # The updated headless engine
        "--no-sandbox",           # Required to run as root/non-privileged in Docker
        "--disable-dev-shm-usage", # Prevents crashes in limited Docker memory
        "--disable-gpu",
        "--remote-debugging-pipe", # CRITICAL: Fixes the "Chrome instance exited" error
        "--window-size=1400,1000"
      ],
      binary: "/usr/bin/chromium"
    )

    Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
  end

  Capybara.javascript_driver = :selenium_chrome_docker
else
  Capybara.default_driver = :selenium_chrome
  Capybara.javascript_driver = :selenium_chrome
end
