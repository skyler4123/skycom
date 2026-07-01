# app/controllers/concerns/application_controller/authentication_concern.rb
module ApplicationController::AuthenticationConcern
  extend ActiveSupport::Concern

  included do
    # This makes the methods available in your views
    helper_method :current_user, :is_signed_in?
  end

  def current_user
    # @current_user ||= current_session&.user
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
    # token is id of Session record
    token = cookies.signed[:session_token]
    return unless token

    # Global cache check — source of truth for session existence
    unless Rails.global_session_cache.exist?(token)
      cleanup_invalid_session(token)
      return
    end

    # Local cache / DB fallback
    session_record = Session.cached_find(token, expires_in: SESSION_CACHE_EXPIRY)
    unless session_record
      Rails.global_session_cache.delete(token)
      cleanup_invalid_session(token)
      return
    end

    # Extend global cache TTL for active users (write with fresh expires_in)
    Rails.global_session_cache.write(token, true, expires_in: COOKIE_EXPIRY)

    Current.session = session_record
  end

  def authenticate
    redirect_to main_app.root_path if !is_signed_in?
  end

  def cleanup_invalid_session(token)
    Rails.local_cache.delete("sessions_#{token}")
    cookies.delete(:session_token)
    cookies.delete(:is_signed_in)
  end
end
