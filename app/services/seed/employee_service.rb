class Seed::EmployeeService
  def self.create(
    company_group:,
    company: nil,
    user: nil,
    name: Faker::Name.name,
    description: "#{Faker::Job.title} in #{Faker::Commerce.department}",
    business_type: nil,
    discarded_at: nil,
    index: 0
  )
    user ||= Seed::UserService.create(username: "company_group_#{company_group.id}_employee", index: index)

    employee = Employee.create!(
      user: user,
      company_group: company_group,
      company: company,
      name: name,
      description: description,
      business_type: business_type || Employee.business_types.keys.sample,
      discarded_at: discarded_at
    )
  end
end
