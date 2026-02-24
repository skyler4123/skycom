# app/controllers/concerns/application_controller/authentication_concern.rb
module ApplicationController::AuthenticationConcern
  extend ActiveSupport::Concern

  included do
    # before_action :set_current_request_details
    # before_action :set_current_session
    # before_action :authenticate
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

    # 1. Generate Key: "session/{token}"
    cache_key = Session.cache_key_for(token)

    # 2. Fetch or Miss
    session_record = Rails.cache.fetch(cache_key, expires_in: 4.hours) do
      Session.find_by(id: token)
    end

    if session_record
      Current.session = session_record
    else
      # If we found nil (record deleted in DB but token exists in cookie), clear cache to be safe
      Rails.cache.delete(cache_key)
    end
  end

  def authenticate
    redirect_to main_app.root_path if !Current.session
  end
end
