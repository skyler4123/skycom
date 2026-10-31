# frozen_string_literal: true

# Blocks a suspended company from using the company-scoped web/JSON surface.
#
# The check runs after authorization so unauthorized users get the normal
# authorization response, never a suspension leak. Web HTML goes to the top-up
# page; JSON returns the standard errors array with 403. Top-Up, Billing, and
# Usage controllers skip this filter so the company can recover.
module Companies::SuspendedCompanyConcern
  extend ActiveSupport::Concern

  COMPANY_SUSPENDED_MESSAGE = "Your company is suspended. Please top up to continue."
  def self.suspended_message = COMPANY_SUSPENDED_MESSAGE

  included do
    before_action :block_suspended_company
  end

  private

  def block_suspended_company
    return unless current_company&.suspended?

    respond_to do |format|
      format.html do
        redirect_to new_company_top_up_path(current_company), alert: COMPANY_SUSPENDED_MESSAGE
      end
      format.json do
        render json: { errors: [ COMPANY_SUSPENDED_MESSAGE ] }, status: :forbidden
      end
      format.any { head :forbidden }
    end
  end
end
