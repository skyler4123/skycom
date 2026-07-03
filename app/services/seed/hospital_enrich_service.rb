class Seed::HospitalEnrichService
  HOSPITAL_ENRICH_EMPLOYEE_COUNTS = {
    Dentist: 3,
    DentalAssistant: 8,
    Receptionist: 5,
    Hygienist: 3,
    Manager: 1
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
    create_shifts
    create_attendance_policies
    create_attendance_event_data
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

  def create_shifts
    puts "Creating shift templates and schedules..."
    templates = []
    @branches.each do |branch|
      [ { name: "Morning",   start: "07:00", end: "15:00" },
        { name: "Afternoon", start: "15:00", end: "23:00" },
        { name: "Night",     start: "23:00", end: "07:00" }
      ].each do |shift_data|
        template = Seed::ShiftTemplateService.create(
          company: @company, branch: branch,
          name: shift_data[:name],
          start_time: shift_data[:start],
          end_time: shift_data[:end],
          policy_type: "fixed",
          full_day_minutes: 480
        )
        templates << template
      end
    end

    # Create scheduled shifts for employees
    @employees.each do |employee|
      template = templates.select { |t| t.branch_id == employee.branch_id }.sample
      next unless template

      date = Date.current + rand(0..7).days
      ScheduledShift.create!(
        company: @company, branch: employee.branch, employee: employee,
        shift_template: template, work_date: date,
        expected_start_at: date.to_time.change(hour: template.start_time.hour, min: template.start_time.min),
        expected_end_at: date.to_time.change(hour: template.end_time.hour, min: template.end_time.min),
        status: :scheduled
      )
    end
  end

  def create_attendance_policies
    puts "Creating attendance policies..."
    @branches.each do |branch|
      AttendancePolicy.create!(
        company: @company, branch: branch,
        latitude: 10.773, longitude: 106.694,
        allowed_radius_meters: 100
      )
    end
  end

  def create_attendance_event_data
    puts "Creating attendance event data..."

    @employees.each do |employee|
      next unless employee.branch

      template = ShiftTemplate.where(company: @company, branch: employee.branch).sample
      next unless template

      # Create past shifts for the last 14 days
      (1..14).each do |day_offset|
        date = Date.current - day_offset.days
        next if date.saturday? || date.sunday? # Skip weekends

        expected_start = date.to_time.change(hour: template.start_time.hour, min: template.start_time.min)
        expected_end = date.to_time.change(hour: template.end_time.hour, min: template.end_time.min)

        shift = ScheduledShift.create!(
          company: @company, branch: employee.branch, employee: employee,
          shift_template: template, work_date: date,
          expected_start_at: expected_start, expected_end_at: expected_end,
          status: :completed
        )

        # Simulate check-in (5-15 min early)
        grace = rand(5..15)
        check_in = expected_start - grace.minutes

        # Simulate check-out (on time or slightly late)
        check_out = expected_end + rand(0..10).minutes

        AttendanceLog.create!(
          company: @company, branch: employee.branch, employee: employee,
          log_type: "check_in", logged_at: check_in
        )
        AttendanceLog.create!(
          company: @company, branch: employee.branch, employee: employee,
          log_type: "check_out", logged_at: check_out
        )

        total_work = ((check_out - check_in) / 60).to_i
        break_min = template.unpaid_break_minutes
        net_work = [ total_work - break_min, 0 ].max
        late = check_in > expected_start ? ((check_in - expected_start) / 60).to_i : 0
        early = check_out < expected_end ? ((expected_end - check_out) / 60).to_i : 0
        overtime = check_out > expected_end ? ((check_out - expected_end) / 60).to_i : 0
        status = early > 60 ? :half_day : :present

        record = AttendanceRecord.create!(
          company: @company, branch: employee.branch, employee: employee,
          scheduled_shift: shift, check_in_at: check_in, check_out_at: check_out,
          total_work_minutes: net_work, late_minutes: late,
          early_leave_minutes: early, overtime_minutes: overtime,
          computed_status: status
        )

      end
    end

    # Run resolution engine
    puts "  -> Running daily resolution..."
    resolved_dates = (1..14).map { |i| Date.current - i.days }.reject { |d| d.saturday? || d.sunday? }
    @employees.each do |emp|
      resolved_dates.each do |date|
        Attendance::DailyResolutionService.new.call(employee: emp, date: date)
      rescue => e
        Rails.logger.warn("Resolution failed for #{emp.id} on #{date}: #{e.message}")
      end
    end
  end
end
