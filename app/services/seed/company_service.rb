class Seed::CompanyService
  def self.run
    User.all.each do |user|
      3.times do |n|
        company = user.companies.create!(
          name: "Company #{n}",
          parent_company: user.companies.sample
        )
      end
    end
  end
end
