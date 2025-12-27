# app/controllers/concerns/single_session_access_concern.rb
module SingleSessionAccessConcern
  extend ActiveSupport::Concern

  included do
    # No automatic before_actions — we want explicit opt-in
  end

  private

  # Call this via before_action in controllers that need single-session protection
  def enable_single_session_access
    prepare_exclusive_token
    enforce_exclusive_session
  end

  def prepare_exclusive_token
    return unless Current.session
    return if cookies.signed[:exclusive_token].present?

    token = SecureRandom.hex(20)
    Current.session.update!(exclusive_token: token)

    update_cookie(session: Current.session, user: Current.user, exclusive_token: token)
  end

  def enforce_exclusive_session
    return unless Current.session

    client_token = cookies.signed[:exclusive_token]

    unless client_token && Current.session.exclusive_token == client_token
      invalidate_current_session
      return
    end

    # Take over: make this the only valid session
    new_token = SecureRandom.hex(20)

    Current.user.update!(exclusive_token: new_token)
    Current.session.update!(exclusive_token: new_token)

    update_cookie(session: Current.session, user: Current.user, exclusive_token: new_token)
  end

  def invalidate_current_session
    Current.session&.destroy

    cookies.delete(:session_token)
    cookies.delete(:exclusive_token)
    cookies.delete(:current_user)
    cookies.delete(:company_groups)
    cookies.delete(:is_signed_in)

    redirect_to main_app.root_path,
      alert: "Your session has been invalidated — another device has taken over. Please sign in again."
  end
end
