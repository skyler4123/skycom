module ApplicationController::CookieConcern
  extend ActiveSupport::Concern

  included do
    def set_sign_in_cookie(session:, user:)
      cookies.signed.permanent[:session_token] = { value: session.id, httponly: true }
      cookies.permanent[:id] = user.id
      cookies.permanent[:email] = user.email
      cookies.permanent[:avatar] = user.avatar || user.avatar_path
      cookies.permanent[:is_signed_in] = true
    end
  end
end
