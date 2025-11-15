class Seed::EmployeeService
  # Define the available kinds for the 'kind' attribute (assuming an enum structure)
  KINDS = Employee.kinds.keys
  
  # Configuration for the number of employees per company
  EMPLOYEES_PER_COMPANY = 5
  
  def self.run
    Company.all.each do |company|
      EMPLOYEES_PER_COMPANY.times do |index|
        assigned_user = Seed::UserService.create(username: "company_#{company.id}_employee", index: index)
        employee = Employee.create!(
          user: assigned_user,
          company: company,
          name: Faker::Name.name,
          # Generate a short, relevant description
          description: Faker::Job.title + ' in ' + Faker::Commerce.department, 
          kind: KINDS.sample, 
          # Set a random discarded_at time if the record should be discarded
          # discarded_at: should_discard ? Time.zone.now - rand(1..30).days : nil
        )

        employee.attach_tag(name: "Employee #{employee.id} Tag")
      end
    end
  end
end
