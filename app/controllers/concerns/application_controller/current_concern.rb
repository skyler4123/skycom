module ApplicationController::CurrentConcern
  extend ActiveSupport::Concern

  included do
    before_action :set_current_company_group_id

    private

    # Get current_company_group_id from Cookie
    def set_current_company_group_id
      if cookies[:current_company_group_id]
        Current.company_group_id = cookies[:current_company_group_id]
      else
        Current.company_group_id = Current.user&.company_groups&.first&.id
        cookies[:current_company_group_id] = Current.company_group_id
      end
    end
  end
end
