
module CompanyGroup::EducationConcern
  extend ActiveSupport::Concern

  included do
    def schools
      companies
    end
  end
end
