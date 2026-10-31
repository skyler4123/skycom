# frozen_string_literal: true

# Mobile equivalent of Companies::SuspendedCompanyConcern. Mobile has no
# top-up flow yet, so a suspended company sees a 403 page telling the owner to
# recover from the web app. Sign-in is outside this controller and stays open.
module Mobile::Companies::SuspendedCompanyConcern
  extend ActiveSupport::Concern

  COMPANY_SUSPENDED_MESSAGE = "Your company is suspended. Please top up on the web to continue."

  included do
    before_action :block_suspended_company
  end

  private

  def block_suspended_company
    return unless @company&.suspended?

    respond_to do |format|
      format.html { render "mobile/shared/suspended", layout: "mobile", status: :forbidden }
      format.json { render json: { errors: [ COMPANY_SUSPENDED_MESSAGE ] }, status: :forbidden }
      format.any { head :forbidden }
    end
  end
end
