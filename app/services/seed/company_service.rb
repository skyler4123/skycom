class Seed::CompanyService
  def self.run
    User.all.each do |user|
      10.times do |n|
        companies = user.companies
        # debugger
        company = Company.create!(
          name: "Company #{n}",
          user: user,
          parent_company: companies.sample
        )
      end
    end
  end
end
