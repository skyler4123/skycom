# frozen_string_literal: true

module MobileGeolocationHelper
  def grant_mobile_geolocation(latitude: 10.773, longitude: 106.694, accuracy: 10)
    page.driver.browser.execute_cdp(
      "Browser.grantPermissions",
      permissions: [ "geolocation" ],
      origin: mobile_geolocation_origin
    )
    page.driver.browser.execute_cdp(
      "Emulation.setGeolocationOverride",
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy
    )
  end

  def deny_mobile_geolocation
    page.driver.browser.execute_cdp(
      "Browser.setPermission",
      permission: { name: "geolocation" },
      setting: "denied",
      origin: mobile_geolocation_origin
    )
  end

  def reset_mobile_geolocation
    page.driver.browser.execute_cdp("Browser.resetPermissions")
    page.driver.browser.execute_cdp("Emulation.clearGeolocationOverride")
  rescue Selenium::WebDriver::Error::WebDriverError
    nil
  end

  private

  def mobile_geolocation_origin
    Capybara.current_session.server&.base_url || Capybara.app_host
  end
end

RSpec.configure do |config|
  config.include MobileGeolocationHelper, type: :feature
  config.after(:each, type: :feature, js: true) { reset_mobile_geolocation }
end
