
module CompanyGroup::RetailConcern
  extend ActiveSupport::Concern

  included do
    def branches
      companies
    end
  end
end
