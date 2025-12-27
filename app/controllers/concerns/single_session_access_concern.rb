# app/controllers/concerns/single_session_access_concern.rb
module SingleSessionAccessConcern
  extend ActiveSupport::Concern

  included do
    # No automatic activation
  end

  private

  def enable_single_session_access
    prepare_single_access_token
    enforce_single_access_session
  end

  def prepare_single_access_token
    # Ensure sign_access_token present at user, session and cookie first
    return if Current.user.single_access_token.present? && Current.session.single_access_token.present? && cookies.signed[:single_access_token].present?

    new_global_token = SecureRandom.hex(20)
    Current.user.update!(single_access_token: new_global_token) if Current.user.single_access_token.nil?
    Current.session.update!(single_access_token: new_global_token) if Current.session.single_access_token.nil?
    update_cookie(session: Current.session, user: Current.user, single_access_token: new_global_token) if !cookies.signed[:single_access_token].present?
  end

  def enforce_single_access_session
    invalidate_current_session if Current.user.single_access_token.nil? || Current.session.single_access_token.nil? || !cookies.signed[:single_access_token].present?
    invalidate_current_session if Current.session.single_access_token != Current.user.single_access_token
    invalidate_current_session if Current.user.single_access_token != cookies.signed[:single_access_token]
    invalidate_current_session if Current.user.single_access_token != Current.session.single_access_token
  end

  def invalidate_current_session
    cookies.clear

    redirect_to main_app.root_path,
      alert: "Your session has been taken over by another device. Please sign in again."
  end
end
