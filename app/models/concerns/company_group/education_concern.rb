
module CompanyGroup::EducationConcern
  extend ActiveSupport::Concern

  included do
    def schools
      branches
    end
  end
end
