class Seed::CompanyService
  def self.run
    User.all.each do |user|
      2.times do |n|
        company = Company.create!(
          name: "Company #{n}",
          user: user
        )
      end
    end
  end
end
