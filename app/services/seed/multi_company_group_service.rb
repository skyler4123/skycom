class Seed::MultiCompanyGroupService
  def initialize(user:)
    Seed::SchoolService.new(user: user)
  end
end
