module ApplicationController::CurrentConcern
  extend ActiveSupport::Concern

  included do
    before_action :set_current_company_business_type

    private

    def set_current_company_business_type
      # Get from Cookie with name 'company_business_type'
      if cookies.signed[:company_business_type].present?
        Current.company_business_type = cookies.signed[:company_business_type]
      else
        Current.company_business_type = nil
      end
    end
  end
end
