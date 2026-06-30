# app/controllers/concerns/application_controller/cookie_concern.rb
module ApplicationController::CookieConcern
  extend ActiveSupport::Concern

  def update_cookie(session:, user:)
    # signed + explicit 1-day expiration
    cookies.signed[:session_token] = {
      value: session.id,
      httponly: true,
      expires: COOKIE_EXPIRY
    }

    # Standard public cookies with explicit 1-day expiration
    cookies[:is_signed_in] = {
      value: true,
      expires: COOKIE_EXPIRY
    }

    cookies[:client_cache_version] = {
      value: cache_version(user: user),
      expires: COOKIE_EXPIRY
    }
  end

  def sync_client_cache_version
    current_version = cache_version(user: current_user)

    # Only update if the version has changed
    return if cookies[:client_cache_version] == current_version

    # Refresh the version value and extend its lifetime for another day
    cookies[:client_cache_version] = {
      value: current_version,
      expires: COOKIE_EXPIRY
    }
  end

  def cache_version(user:)
    return "0" unless user

    latest_update = [
      user.updated_at,
      Company.cached_where(user: user).maximum(:updated_at)
    ].compact.max.to_i

    latest_update.to_s
  end
end
