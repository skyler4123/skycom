# app/controllers/concerns/application_controller/cookie_concern.rb
module ApplicationController::CookieConcern
  extend ActiveSupport::Concern

  def update_cookie(session:, user:)
    cookies.signed.permanent[:session_token] = { value: session.id, httponly: true }
    cookies.permanent[:is_signed_in] = true
    cookies.permanent[:client_cache_version] = cache_version(user: user)
  end

  def sync_client_cache_version
    # Only write to the cookie if the version has changed
    return if cookies[:client_cache_version] == cache_version(user: current_user)
    cookies.permanent[:client_cache_version] = cache_version(user: current_user)
  end

  def cache_version(user:)
    # If a company name changes or a branch is added, this hash changes.
    latest_update = [
      user.updated_at,
      user.companies.maximum(:updated_at)
    ].compact.max.to_i

    # Convert to a string for comparison
    latest_update.to_s
  end
end
