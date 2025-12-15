class Seed::MultiCompanyGroupService
  def initialize(user:)
    Seed::RetailService.new(user: user)
    Seed::EducationService.new(user: user)
  end
end
