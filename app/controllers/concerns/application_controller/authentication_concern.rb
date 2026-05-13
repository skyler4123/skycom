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

    session_record = Session.cached_find(token)
    Current.session = session_record
  end

  def authenticate
    redirect_to main_app.root_path if !is_signed_in?
  end
end
