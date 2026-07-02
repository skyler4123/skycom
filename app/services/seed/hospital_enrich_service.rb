class Seed::HospitalEnrichService
  HOSPITAL_ENRICH_EMPLOYEE_COUNTS = {
    Dentist: 3,
    DentalAssistant: 8,
    Receptionist: 5,
    Hygienist: 3,
    PracticeManager: 1
  }.freeze

  HOSPITAL_ENRICH_CUSTOMER_COUNTS = { Patient: 50 }.freeze

  def initialize(user:, email: Faker::Internet.email, name: nil, company: nil,
                 country_code: :us, currency_code: :usd, timezone: :minus_5,
                 address_line_1: nil, city: nil, postal_code: nil)
    @multi_company_owner = user
    @name = name || company&.name
    @country_code = country_code || company&.country_code || :us
    @currency_code = currency_code || company&.currency_code || :usd
    @timezone = timezone || company&.timezone || :minus_5
    @address_line_1 = address_line_1
    @city = city
    @postal_code = postal_code
    @company = company
    @branches = []
    @departments = []
    @employees = []
    @patients = []
    @services = []
    @facilities = []
    @employee_counter = 0
    @patient_counter = 0
    @facility_counter = 0
    @email = email
    @email_domain = EmailService.new(email).full_domain
    seeding
  end

  def seeding
    print_header

    create_hospital_company unless @company
    create_branches
    create_departments
    create_facilities
    create_employees
    assign_employees_to_departments
    create_patients
    create_services
    create_appointments
    create_billing_data

    print_footer
    true
  end

  private

  def print_header
    puts "\n\n🏥 Starting Hospital Company Seeding..."
    puts "========================================================="
  end

  def print_footer
    puts "\n========================================================="
    puts "🏥 Hospital Company Seeding Complete!"
    puts "========================================================="
  end

  def create_hospital_company
    @company = Seed::CompanyService.create(
      user: @multi_company_owner,
      name: @name || "Company #{Company.count + 1}",
      email: @email,
      description: "A dental clinic group",
      business_type: HOSPITAL_INIT_COMPANY_GROUP_BUSINESS_TYPE,
      country_code: @country_code,
      currency_code: @currency_code,
      timezone: @timezone,
      address_line_1: @address_line_1,
      city: @city,
      postal_code: @postal_code
    )
  end

  def create_branches(count: 2)
    puts "Creating #{count} clinic branches..."
    branch_categories = Category.where(company: @company, resource_name: "branches").to_a
    count.times do |i|
      branch = Seed::BranchService.create(
        name: "Clinic #{i + 1}",
        description: "Description for Clinic #{i + 1}",
        company: @company,
        category: branch_categories[i % branch_categories.length]
      )
      branch.address = Seed::AddressService.create(country_code: @country_code)
      branch.save!
      @branches << branch
    end
  end

  def create_departments
    puts "Creating dental departments..."
    dept_categories = Category.where(company: @company, resource_name: "departments").to_a
    [ "Orthodontics", "Endodontics", "Periodontics", "Oral Surgery", "Pediatrics" ].each_with_index do |dept_name, i|
      department = Seed::DepartmentService.create(
        company: @company,
        name: dept_name,
        description: "Department: #{dept_name}",
        category: dept_categories[i % dept_categories.length]
      )
      department.save!
      @departments << department
    end
  end

  def create_facilities
    puts "Creating clinic facilities..."
    @branches.each do |branch|
      facility_categories = Category.where(company: @company, resource_name: "facilities").to_a
      [ "Treatment Room", "Operatory", "X-ray Room", "Sterilization Room", "Consultation Room", "Recovery Area" ].each_with_index do |name, i|
        @facility_counter += 1
        facility = Seed::FacilityService.create(
          company: @company,
          branch: branch,
          name: "#{name} #{@facility_counter}",
          category: facility_categories[i % facility_categories.length]
        )
        @facilities << facility
      end
    end
  end

  def create_employees
    puts "Creating employees..."
    @branches.each_with_index do |branch, index|
      HOSPITAL_ENRICH_EMPLOYEE_COUNTS.each do |role_name, count|
        count.times do |i|
          user = Seed::UserService.create(
            parent_user: @multi_company_owner,
            email: "#{role_name}_#{i + 1}_clinic_#{index + 1}@#{@email_domain}",
            system_role: :company_employee
          )
          @employee_counter += 1
          employee = Seed::EmployeeService.create(
            user: user, company: @company, branch: branch,
            name: "Employee #{@employee_counter}"
          )
          employee.attach_role(role_name)
          employee.save!
          @employees << employee
        end
      end
    end
  end

  def assign_employees_to_departments
    @employees.each do |employee|
      Seed::DepartmentAppointmentService.create(
        company: @company,
        department: @departments.sample,
        appoint_to: employee
      )
    end
  end

  def create_patients
    puts "Creating patients..."
    @branches.each do |branch|
      HOSPITAL_ENRICH_CUSTOMER_COUNTS.each do |_, count|
        count.times do |i|
          user = Seed::UserService.create(
            parent_user: @multi_company_owner,
            email: "patient_#{i + 1}_#{branch.id}@example.com",
            system_role: :company_customer
          )
          @patient_counter += 1
          patient = Seed::CustomerService.create(
            user: user, company: @company, branch: branch, name: "Patient #{@patient_counter}"
          )
          @patients << patient
        end
      end
    end
  end

  def create_services
    puts "Creating treatment services..."
    service_categories = Category.where(company: @company, resource_name: "services").to_a
    [ "Cleaning & Exam", "Filling", "Root Canal", "Crown", "Extraction", "Whitening", "Implant", "Brace", "Invisalign", "Emergency" ].each_with_index do |svc_name, i|
      @branches.each do |branch|
        service = Seed::ServiceService.create(
          company: @company,
          branch: branch,
          name: "#{svc_name} - #{branch.name}",
          duration: [ 30, 45, 60, 90 ].sample,
          category: service_categories[i % service_categories.length]
        )
        @services << service
      end
    end
  end

  def create_appointments
    puts "Creating appointments..."
    @branches.each do |branch|
      branch_patients = @patients.select { |p| p.branch_id == branch.id }
      next if branch_patients.empty?

      5.times do |i|
        patient = branch_patients.sample
        order = Seed::OrderService.create(
          company: @company, branch: branch, customer: patient,
          name: "Appointment #{i + 1} for #{patient.name}"
        )
        attach_treatments_to_order(branch, order)
      end
    end
  end

  def attach_treatments_to_order(branch, order)
    branch_services = @services.select { |s| s.branch_id == branch.id }
    branch_services.sample(rand(1..3)).each do |service|
      OrderAppointment.create!(
        company: @company, order: order, appoint_to: service,
        quantity: 1, unit_price: rand(50.0..500.0).round(2), total_price: 0
      )
    end
  end

  def create_billing_data
    puts "Generating billing data..."
    Seed::BillingDataService.create(company: @company)
  end
end
