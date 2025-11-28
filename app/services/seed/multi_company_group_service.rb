class Seed::MultiCompanyGroupService
  def initialize(user)
    @user = user
    @company_groups = []
  end

  def self.create(owner_email:)
    user = User.find_by!(email: owner_email)
    service = new(user)
    companies = []
    count.times do
      company = Seed::CompanyGroupService.create(user: user)
      companies << company
    end
    companies
  end
end