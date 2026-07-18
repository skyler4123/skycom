class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Core authentication for all controllers
  include ApplicationController::AuthenticationConcern

  # Provides single-session protection methods (opt-in only)
  include ApplicationController::SingleSessionAccessConcern

  # Cookie management helpers
  include ApplicationController::CookieConcern

  include Pagy::Method

  # Universal filters
  before_action :set_current_request_details
  before_action :set_current_session
  before_action :authenticate
  # We only sync client_cache when user signed in that require current_user
  before_action :sync_client_cache_version, if: :current_user
  before_action :set_paper_trail_whodunnit
  before_action :set_websocket_channels

  private

  def set_websocket_channels
    @channels = []
    @channels << "company_#{current_company&.id}_notifications" if current_company
    @channels << "company_#{current_company&.id}_top_up" if current_company
    @channels << "user_#{current_user&.id}_alerts" if current_user
  end

  # --------------------------------------------------------------------------
  # SINGLE-SESSION MODE
  #
  # To restrict a controller (or specific actions) to ONLY ONE active device
  # at a time (e.g., banking, payments, sensitive settings), add this line:
  #
  #   before_action :enable_single_session_access
  #
  # Examples:
  #
  #   class BankingController < ApplicationController
  #     before_action :enable_single_session_access
  #   end
  #
  #   class PaymentsController < ApplicationController
  #     before_action :enable_single_session_access, only: [:new, :create, :confirm]
  #   end
  #
  # This keeps normal pages fully multi-device compatible.
  # --------------------------------------------------------------------------
end
