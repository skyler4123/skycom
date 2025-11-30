module ApplicationController::CurrentConcern
  extend ActiveSupport::Concern

  included do
    before_action :set_current_company_group_business_type

    private

    # Get current_company_group_business_type from Cookie
    def set_current_company_group_business_type
      if cookies[:current_company_group_business_type]
        Current.company_group_business_type = cookies[:current_company_group_business_type]
      else
        Current.company_group_business_type = Current.user.first_company_group_business_type
        cookies[:current_company_group_business_type] = Current.company_group_business_type
      end
    end
  end
end
