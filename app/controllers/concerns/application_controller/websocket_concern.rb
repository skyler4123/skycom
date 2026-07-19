# app/controllers/concerns/application_controller/single_session_access_concern.rb
module ApplicationController::WebsocketConcern
  extend ActiveSupport::Concern

  included do
    # No automatic activation
  end

  def set_websocket_channels
    return unless is_signed_in? && @current_company
    @channels = []

    # Clean, safe, and entirely abstracted out via your service wrapper
    @channels << WEBSOCKET.company_channel(current_company&.id) if current_company
    @channels << WEBSOCKET.user_channel(current_user&.id)       if current_user

    @channels.compact! # Safe guard against edge nils
  end
end
