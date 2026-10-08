# app/controllers/concerns/application_controller/single_session_access_concern.rb
module ApplicationController::WebsocketConcern
  extend ActiveSupport::Concern

  included do
    # No automatic activation
  end

  def set_websocket_channels
    return unless is_signed_in? && @current_company
    @channels = []
    @channels << WEBSOCKET::EVENTS[:test] if !Rails.env.production?
    @channels << WEBSOCKET.channel_name(:company, current_company&.id) if current_company
    @channels << WEBSOCKET.channel_name(:user, current_user&.id)       if current_user

    @channels.compact! # Safe guard against edge nils
  end
end
