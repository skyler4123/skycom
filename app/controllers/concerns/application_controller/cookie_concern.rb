# app/controllers/concerns/application_controller/cookie_concern.rb
module ApplicationController::CookieConcern
  extend ActiveSupport::Concern

  def update_cookie(session:, user:)
    # current_user = { id: user.id, email: user.email, avatar: user.avatar_url }
    cookies.signed.permanent[:session_token] = { value: session.id, httponly: true }
    cookies.permanent[:is_signed_in] = true
    # cookies.permanent[:current_user] = current_user.to_json
    # cookies.permanent[:companies] = user.companies.to_json

    # Create a version hash based on the user and their companies
    # If a company name changes or a branch is added, this hash changes.
    cache_version = Digest::MD5.hexdigest([
      user.updated_at,
      user.companies.maximum(:updated_at)
    ].join('-'))

    cookies.permanent[:client_cache_version] = cache_version
  end

  def sync_client_cache_version
    # Generate the version based on the latest timestamps
    latest_update = [
      current_user.updated_at,
      current_user.companies.maximum(:updated_at)
    ].compact.max.to_i

    # Convert to a string for comparison
    current_version = latest_update.to_s

    # Only write to the cookie if the version has changed
    if cookies[:client_cache_version] != current_version
      cookies.permanent[:client_cache_version] = current_version
    end
  end
end
