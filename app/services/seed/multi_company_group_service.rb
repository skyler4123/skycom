class Seed::MultiCompanyGroupService
  def initialize(owner_email:)
    multi_company_group_owner = Seed::UserService.create(email: owner_email)
    Seed::SchoolService.new(user: multi_company_group_owner)
  end
end
