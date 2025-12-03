
module CompanyGroup::RetailConcern
  extend ActiveSupport::Concern

  included do
    def stores
      companies
    end
  end
end
