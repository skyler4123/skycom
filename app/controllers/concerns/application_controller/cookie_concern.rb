# app/controllers/concerns/application_controller/cookie_concern.rb
module ApplicationController::CookieConcern
  extend ActiveSupport::Concern

  def update_cookie(session:, user:)
    current_user = { id: user.id, email: user.email, avatar: user.avatar_url }
    cookies.signed.permanent[:session_token] = { value: session.id, httponly: true }
    cookies.permanent[:is_signed_in] = true
    cookies.permanent[:current_user] = current_user.to_json
    cookies.permanent[:companies] = user.companies.to_json
  end
end
