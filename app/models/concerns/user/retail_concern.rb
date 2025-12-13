module User::RetailConcern
  extend ActiveSupport::Concern

  included do
    def retails
      company_groups.where(business_type: :retail)
    end

    def retail
      retails.first
    end
  end
end
