module ApplicationController::CookieConcern
  extend ActiveSupport::Concern

  included do
    def set_sign_in_cookie(session:, user:)
      cookies.signed.permanent[:session_token] = { value: session.id, httponly: true }
      cookies.permanent[:id] = user.id
      cookies.permanent[:email] = user.email
      cookies.permanent[:avatar] = user.avatar || user.avatar_path
      cookies.permanent[:is_signed_in] = true

      company_groups = user.company_groups.map do |company_group|
        { name: company_group.name, url: company_group_path(company_group) }
      end
      cookies.permanent[:company_groups] = company_groups.to_json

    end
  end
end
