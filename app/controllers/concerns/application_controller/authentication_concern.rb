# app/controllers/concerns/application_controller/authentication_concern.rb
module ApplicationController::AuthenticationConcern
  extend ActiveSupport::Concern

  # Per-session cache TTL for Session.cached_find. Longer than DEFAULT_CACHE_EXPIRY
  # because session records rarely change and the global cache (Redis) provides
  # cross-instance invalidation.
  SESSION_CACHE_EXPIRY = 1.hour

  included do
    helper_method :current_user, :is_signed_in?
  end

  def current_user
    @current_user ||= User.cached_find(current_session&.user_id)
  end

  def current_session
    @current_session ||= Current.session
  end

  def is_signed_in?
    return false unless cookies[:is_signed_in]
    current_session.present?
  end

  private

  def set_current_request_details
    Current.user_agent = request.user_agent
    Current.ip_address = request.ip
  end

  def set_current_session
    token = cookies.signed[:session_token]
    return unless token

    # Pure L1 read (Local Cache + Pub/Sub invalidation on destroy/logout)
    session_record = Session.cached_find(token, expires_in: SESSION_CACHE_EXPIRY)

    unless session_record
      cleanup_invalid_session(token)
      return
    end

    Current.session = session_record
  end

  def authenticate
    redirect_to main_app.root_path if !is_signed_in?
  end

  def cleanup_invalid_session(token)
    Rails.sync_cache.delete("sessions_#{token}")
    cookies.delete(:session_token)
    cookies.delete(:is_signed_in)
  end
end
