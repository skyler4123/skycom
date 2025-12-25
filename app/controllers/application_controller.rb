class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :set_current_request_details
  before_action :set_current_session
  before_action :authenticate
  before_action :require_active_subscription!

  # ------------------------------------------------------------------------
  include ApplicationController::CookieConcern
  # ------------------------------------------------------------------------

  private
  def set_current_request_details
    Current.user_agent = request.user_agent
    Current.ip_address = request.ip
  end

  def set_current_session
    session_record = Session.find_by_id(cookies.signed[:session_token])
    Current.session = session_record if session_record
  end

  def authenticate
    # redirect_to sign_in_path if !Current.session
    redirect_to root_path if !Current.session
  end

  def require_active_subscription!
    # Ensure we have a user (skip if not logged in, or handle authentication first)
    return unless Current.user

    unless Current.user.active_subscriber?
      # Adjust 'pricing_path' to your actual route helper
      redirect_to pricing_path, alert: "You need an active subscription to access this page."
    end
  end
end
