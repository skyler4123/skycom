class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Core authentication for all controllers
  include ApplicationController::AuthenticationConcern

  # Provides single-session protection methods (opt-in only)
  include ApplicationController::SingleSessionAccessConcern

  # Cookie management helpers
  include ApplicationController::CookieConcern

  # Universal filters
  before_action :set_current_request_details
  before_action :set_current_session
  before_action :authenticate

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
