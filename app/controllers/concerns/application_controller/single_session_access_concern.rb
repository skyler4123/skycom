# app/controllers/concerns/application_controller/single_session_access_concern.rb
module ApplicationController::SingleSessionAccessConcern
  extend ActiveSupport::Concern

  included do
    # No automatic activation
  end

  private

  def enable_single_session_access
    invalidate_current_session if Current.user.single_access_token !=Current.session.single_access_token
  end

  def invalidate_current_session
    cookies.clear

    redirect_to main_app.root_path,
      alert: "Your session has been taken over by another device. Please sign in again."
  end
end
