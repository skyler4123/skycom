# frozen_string_literal: true

# This file configures Capybara to use a remote Selenium driver.
# Place this file in `spec/support/` and ensure it's loaded by your test runner.
# For RSpec, this is typically handled by `rails_helper.rb`.

require 'capybara/rails'
require 'capybara/rspec'
require 'selenium-webdriver'

# Run native local
# Capybara.default_max_wait_time = 5
# Capybara.default_driver = :selenium_chrome
# Capybara.javascript_driver = :selenium_chrome

# 🛑 ADD THIS LINE TO SUPPRESS DEBUG/INFO LOGS
Selenium::WebDriver.logger.level = :warn

# Run inside docker
# Configure Capybara to use a remote browser
Capybara.configure do |config|
  # Set the app host to the name of the Rails service in your docker-compose file.
  # This allows the Selenium container to find the Rails application.
  # Capybara will prepend this to your `visit` calls.
  # config.app_host = 'http://192.168.0.100:3000'
  config.app_host = 'http://web:3000'

  config.server_host = '0.0.0.0' # Allow Rails test server to accept external connections
  config.server_port = 3000 # Match your Rails server port
  # Register a custom driver for remote Selenium
  Capybara.register_driver :remote_selenium_chrome do |app|
    # A standard Capybara configuration block that tells Capybara how to
    # communicate with the Selenium Hub.
    Capybara::Selenium::Driver.new(
      app,
      browser: :remote,
      # The URL for the Selenium Hub is based on the service name from docker-compose.yml.
      # The host `selenium-chromium` is the name of the service, and `4444` is the exposed port.
      url: "http://selenium-chromium:4444/wd/hub",
      # url: "http://localhost:4444/wd/hub",

      # Add capabilities for the browser (e.g., to run headless)
      capabilities: Selenium::WebDriver::Options.chrome(
        "goog:chromeOptions": { "args": [ "--headless", "--disable-gpu", "--no-sandbox" ] }
        # "goog:chromeOptions": { "args": ["--disable-gpu", "--no-sandbox"] }

      )
    )
  end

  # # Use the custom registered driver as the default for JavaScript tests
  config.javascript_driver = :remote_selenium_chrome
  # config.javascript_driver = :selenium_chrome
end
