# frozen_string_literal: true

# == Why this file exists
#
# Capybara 3.40.0 — the newest release, no newer version or prerelease exists —
# clears browser storage after every example by sending this Chrome DevTools
# command with a wildcard origin:
#
#   # capybara-3.40.0/lib/capybara/selenium/driver_specializations/chrome_driver.rb:54
#   execute_cdp('Storage.clearDataForOrigin', origin: '*',
#                storageTypes: storage_types_to_clear)
#
# Chrome 158 validates that argument and rejects the wildcard, so every JS
# feature spec failed in the `Capybara.reset_sessions!` after-hook with:
#
#   Selenium::WebDriver::Error::InvalidArgumentError:
#     invalid argument: * is not a valid URL
#
# Capybara's master branch still sends "*" (checked 2026-11-18), so there is no
# upstream fix to upgrade to. This file rewrites the wildcard to the origin the
# test actually runs on. Cookies and local storage are still cleared for that
# origin, so session state cannot leak between examples.
#
# == How to remove this file
#
# 1. Check whether upstream still sends the wildcard:
#
#      grep -n "origin:" \
#        "$(bundle show capybara)/lib/capybara/selenium/driver_specializations/chrome_driver.rb"
#
#    If that line no longer passes `origin: "*"` (or Capybara is gone from the
#    Gemfile because the JS driver changed), continue.
# 2. Delete this file and `spec/gems/capybara_storage_reset_spec.rb`.
# 3. Run `bundle exec rspec spec/features/authentication_spec.rb` — it must stay
#    green without this file.
#
# Nothing else references this file: `spec/rails_helper.rb` auto-requires every
# file under `spec/support/`, so deleting it is enough.

require "capybara/rails"
require "capybara/selenium/driver_specializations/chrome_driver"

module CapybaraStorageReset
  COMMAND = "Storage.clearDataForOrigin"

  # "http://127.0.0.1:41234/" => "http://127.0.0.1:41234"
  def self.origin(base_url)
    return nil if base_url.blank?

    uri = URI.parse(base_url)
    "#{uri.scheme}://#{uri.host}:#{uri.port}"
  rescue URI::InvalidURIError
    nil
  end

  def self.current_origin
    origin(Capybara.app_host.presence || Capybara.current_session&.server&.base_url)
  end

  private

  def execute_cdp(cmd, params = {})
    return super unless cmd == COMMAND && params[:origin] == "*"

    # No app_host and no server means no browser page to clear.
    resolved = CapybaraStorageReset.current_origin
    return nil if resolved.nil?

    super(cmd, params.merge(origin: resolved))
  end
end

Capybara::Selenium::Driver::ChromeDriver.prepend(CapybaraStorageReset)
