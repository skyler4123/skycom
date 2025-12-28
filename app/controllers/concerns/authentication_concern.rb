# app/controllers/concerns/authentication_concern.rb
module AuthenticationConcern
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
    session_record = Session.find_by_id(cookies.signed[:session_token])
    Current.session = session_record if session_record
  end

  def authenticate
    return redirect_to main_app.root_path if !Current.session
  end
end
