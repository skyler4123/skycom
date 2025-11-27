class Seed::HospitalService
  # Define the number of employees to create for each role
  EMPLOYEE_COUNTS = {
    'Director' => 1,
    'Admin' => 2,
    'Doctor' => 8,
    'Nurse' => 15,
    'Receptionist' => 3,
    'Pharmacist' => 2,
    'Cleaner' => 4,
    'Security' => 2,
  }.freeze

  PATIENT_COUNTS = {
    'Patient' => 50
  }.freeze

  # Define the standard roles to be created for each hospital
  HOSPITAL_ROLES = (EMPLOYEE_COUNTS.keys + PATIENT_COUNTS.keys).freeze

  def initialize(owner_email:)
    @owner_email = owner_email
    @hospital_owner = nil
    @hospitals = []
    @employees = []
    @patients = [] # Mapping patients to customers
    @doctors = []
    @departments = []
    @wards = []

    @hospital_count = 2
    @patient_count = 50 # Patients per hospital
    @department_count = 4
    @ward_count = 5

    seed
  end

  def seed
    puts "\n\n🏥 Starting Hospital Seeding..."
    puts "========================================================="

    # --- 1. Create Hospital Owner (User) ---
    puts "Creating 1 hospital owner..."
    @company_business_type = User.company_business_types[:hospital]
    @hospital_owner = Seed::UserService.create(email: @owner_email, company_business_type: @company_business_type)

    #--- 2. Create Hospitals (Company) ---
    puts "Creating #{@hospital_count} hospitals..."
    @hospital_count.times do |i|
      hospital = Seed::CompanyService.create(
        user: @hospital_owner,
        name: "Hospital #{i + 1}",
        description: "A leading healthcare facility - Hospital #{i + 1}",
        parent_company: nil
      )
      @hospitals << hospital
    end
    puts "Created #{@hospitals.count} hospitals."
    
    # --- 3. Create Payment Method Appointments for Hospitals (Companies) ---
    @hospitals.each do |hospital|
      2.times do
        Seed::PaymentMethodAppointmentService.create(
          company: hospital
        )
      end
    end
    puts "Appointed some payment methods to each hospital."

    # --- 4. Create Hospital Roles + Custom Roles ---
    HOSPITAL_ROLES.each do |role_name|
      @hospitals.each do |hospital|
        Seed::RoleService.create(
          company: hospital,
          name: role_name,
          description: "#{role_name} role for #{hospital.name}"
        )
      end
    end

    # --- 5. Create Employees for Each Hospital (Company) ---
    @hospitals.each do |hospital|
      puts "Creating employees for #{hospital.name}..."
      EMPLOYEE_COUNTS.each do |role_name, count|
        count.times do |i|
          user = Seed::UserService.create(parent_user: @hospital_owner, email: "#{role_name.downcase}_#{i + 1}_#{hospital.id}@example.com")
          employee = Seed::EmployeeService.create(
            user: user,
            company: hospital
          )
          employee.attach_tag(name: "Employee #{employee.id} Tag")
          employee.attach_role(role_name)
          @employees << employee
          
          # Track doctors separately for later assignment
          @doctors << employee if role_name == 'Doctor'
        end
      end
      puts "Created #{@employees.count} employees for #{hospital.name}."
    end

    # --- 6. Create Patients (Customers) for Each Hospital (Company) ---
    @hospitals.each do |hospital|
      puts "Creating patients for #{hospital.name}..."
      PATIENT_COUNTS.each do |role_name, count|
        count.times do |i|
          user = Seed::UserService.create(parent_user: @hospital_owner, email: "patient_#{i + 1}_#{hospital.id}@example.com")
          patient = Seed::CustomerService.create(
            user: user,
            company: hospital
          )
          patient.attach_tag(name: "Patient #{patient.id} Tag")
          patient.attach_role(role_name)
          @patients << patient
        end
      end
      puts "Created #{@patients.count} patients for #{hospital.name}."
    end

    # --- 7. Create Departments (Customer Groups) and Admit Patients ---
    @hospitals.each do |hospital|
      puts "Creating departments and admitting patients for #{hospital.name}..."
      @department_count.times do |i|
        department = Seed::CustomerGroupService.create(
          company: hospital,
          name: "Department #{i + 1} - #{hospital.name}",
          description: "#{['Cardiology', 'Neurology', 'Orthopedics', 'Pediatrics'][i]} department"
        )
        department.attach_tag(name: "Department #{department.id} Tag")
        
        # Admit random patients to this department
        hospital_patients = @patients.select { |p| p.company_id == hospital.id }
        admitted_patients = hospital_patients.sample(10)
        admitted_patients.each do |patient|
          Seed::CustomerGroupAppointmentService.create(
            customer_group: department,
            appoint_to: patient
          )
        end
        @departments << department
      end
      puts "Created #{@department_count} departments and admitted patients for #{hospital.name}."
    end

    # --- 8. Create Wards (Facilities) for Each Hospital ---
    puts "Creating wards (facilities) for hospital..."
    @hospitals.each do |hospital|
      @ward_count.times do |i|
        ward_types = ['General Ward', 'ICU', 'Emergency', 'Pediatric Ward', 'Surgical Ward']
        ward = Seed::FacilityService.create(
          company: hospital,
          name: "#{ward_types[i % ward_types.length]} - #{hospital.name}",
          description: "Description for #{ward_types[i % ward_types.length]} in #{hospital.name}"
        )
        ward.attach_tag(name: "Ward #{ward.id} Tag")
        @wards << ward
      end
      puts "Created #{@ward_count} wards for #{hospital.name}."
    end

    # --- 9. Assign Doctors (Employees) to Departments (Services) ---
    @hospitals.each do |hospital|
      puts "Assigning doctors to departments for #{hospital.name}..."
      hospital_doctors = @doctors.select { |d| d.company_id == hospital.id }
      @departments.each do |department|
        # Assign 2-3 doctors per department
        assigned_doctors = hospital_doctors.sample(rand(2..3))
        assigned_doctors.each do |doctor|
          Seed::CustomerGroupAppointmentService.create(
            customer_group: department,
            appoint_from: hospital,
            appoint_to: doctor,
            name: "#{doctor.name || doctor.id} in #{department.name}",
            description: "Doctor assigned to department",
            code: "DOCASSIGN-#{SecureRandom.hex(3).upcase}"
          )
        end
      end
      puts "Assigned doctors to departments for #{hospital.name}."
    end

    # --- 10. Create Services (Medical Services) for Each Hospital ---
    @hospitals.each do |hospital|
      puts "Creating medical services for #{hospital.name}..."
      medical_services = ['Consultation', 'Surgery', 'X-Ray', 'Lab Test', 'Physical Therapy']
      medical_services.each do |service_name|
        service = Seed::ServiceService.create(
          company: hospital,
          name: "#{service_name} - #{hospital.name}",
          description: "#{service_name} service at #{hospital.name}"
        )
        service.attach_tag(name: "Service #{service.id} Tag")
      end
      puts "Created #{medical_services.count} medical services for #{hospital.name}."
    end

    puts "\n========================================================="
    puts "🏥 Hospital Seeding Complete!"
    puts "========================================================="
    true
  end
end
