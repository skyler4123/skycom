class Seed::MultiCompanyGroupService
  def initialize(user:)
    Seed::RetailService.new(user: user)
    Seed::SchoolService.new(user: user)
    # Seed::SchoolService.new(user: user)

  end
end
