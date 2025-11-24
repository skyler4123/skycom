class Seed::EmployeeService

  # Define the available business_types for the 'business_type' attribute (assuming an enum structure)
  BUSINESS_TYPES = Employee.business_types.keys
  
  # Configuration for the number of employees per company
  EMPLOYEES_PER_COMPANY = 5
  
  def self.run
    puts "Seeding Employee records..."
 
    Company.all.each do |company|
      EMPLOYEES_PER_COMPANY.times do |index|
        assigned_user = Seed::UserService.create(username: "company_#{company.id}_employee", index: index)
        employee = Employee.create!(
          user: assigned_user,
          company: company,
          name: Faker::Name.name,
          # Generate a short, relevant description
          description: Faker::Job.title + ' in ' + Faker::Commerce.department, 
          business_type: BUSINESS_TYPES.sample, 
          # Set a random discarded_at time if the record should be discarded
          # discarded_at: should_discard ? Time.zone.now - rand(1..30).days : nil
        )

        employee.attach_tag(name: "Employee #{employee.id} Tag")
      end
    end
 
    puts "Successfully created #{Employee.count} Employee records."
  end

  def self.create(
    company:,
    user: nil,
    name: Faker::Name.name,
    description: "#{Faker::Job.title} in #{Faker::Commerce.department}",
    business_type: nil,
    discarded_at: nil,
    index: 0
  )
    user ||= Seed::UserService.create(username: "company_#{company.id}_employee", index: index)

    employee = Employee.create!(
      user: user,
      company: company,
      name: name,
      description: description,
      business_type: business_type || Employee.business_types.keys.sample,
      discarded_at: discarded_at
    )
  end
end
