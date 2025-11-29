class Seed::SchoolService
  # Define the number of employees to create for each role
  EMPLOYEE_COUNTS = {
    'Principal' => 1,
    'Admin' => 2,
    'Teacher' => 5,
    'Accountant' => 2,
    'Cleaner' => 3,
    'Guard' => 3,
  }.freeze

  CUSTOMER_COUNTS = {
    'Student' => 10
  }.freeze

  # Define the standard roles to be created for each school
  SCHOOL_ROLES = (EMPLOYEE_COUNTS.keys + CUSTOMER_COUNTS.keys).freeze

  COMPANY_GROUP_BUSINESS_TYPE = :school

  def initialize(user:)
    @multi_company_group_owner = user
    @school_group = nil
    @schools = []
    @employees = []
    seeding
  end

  def seeding
    puts "\n\n🏫 Starting School Company Group Seeding..."
    puts "========================================================="

    # --- 1. Create School Company Group ---
    puts "Creating 1 school company group..."
    @school_group = Seed::CompanyGroupService.create(
      user: @multi_company_group_owner,
      name: "School Company Group",
      description: "A group for multiple school companies",
      business_type: COMPANY_GROUP_BUSINESS_TYPE
    )
    puts "Created school company group: #{@school_group.name}"

    #--- 2. Create Schools (Companies) under the Company Group ---
    school_count = 2
    puts "Creating #{school_count} schools under the company group..."
    school_count.times do |i|
      school = Seed::CompanyService.create(
        name: "School #{i + 1}",
        description: "Description for School #{i + 1}",
        parent_company: nil,
        company_group: @school_group
      )
      school.attach_tag(user: @multi_company_group_owner, name: "School #{school.id} Tag")
      @schools << school
    end
    puts "Created #{@schools.count} schools under the company group."

    #--- 3. Create Payment Method Appointments for Schools (Companies) ---
    @schools.each do |school|
      2.times do
        Seed::PaymentMethodAppointmentService.create(
          company_group: @school_group,
        )
      end
    end
    puts "Appointed some payment methods to each school."

    # --- 4. Create School Roles + Custom Roles ---
    SCHOOL_ROLES.each do |role_name|
      Seed::RoleService.create(
        company_group: @school_group,
        name: role_name,
        description: "#{role_name} role for #{@school_group.name}"
      )
    end
    # --- 5. Create Departments (Empoylee Groups) for Each School (Company) ---
    @schools.each do |school|
      puts "Creating departments for #{school.name}..."
      ['Science Department', 'Math Department', 'Arts Department', 'Sports Department'].each do |dept_name|
        department = Seed::EmployeeGroupService.create(
          company_group: @school_group,
          name: dept_name,
          description: "Department: #{dept_name} in #{school.name}"
        )
        department.attach_tag(user: @multi_company_group_owner, name: "Department #{department.id} Tag")
        # Assign department to school via appointment
        Seed::EmployeeGroupAppointmentService.create(
          employee_group: department,
          appoint_to: school
        )
      end
      puts "Created departments for #{school.name}."
    end
    puts "Created departments for all schools."

    # --- 6. Create Employees for Each School (Company) ---
    @schools.each do |school|
      puts "Creating employees for #{school.name}..."
      EMPLOYEE_COUNTS.each do |role_name, count|
        count.times do |i|
          user = Seed::UserService.create(parent_user: @school_owner, email: "#{role_name.downcase}_#{i + 1}_#{school.id}@example.com")
          employee = Seed::EmployeeService.create(
            user: user,
            company_group: @school_group,
            company: school
          )
          employee.attach_tag(user: @multi_company_group_owner, name: "Employee #{employee.id} Tag")
          employee.attach_role(role_name)
          @employees << employee
        end
      end
      puts "Created #{@employees.count} employees for #{school.name}."
    end


  end
  # def initialize(owner_email:)
  #   @owner_email = owner_email
  #   @school_owner = nil
  #   @school_admin = []
  #   @schools = []
  #   @employees = []
  #   @customers = [] # Mapping students to customers
  #   @teachers = []
  #   @classrooms = []
  #   @classes = []
  #   @courses = []

  #   @school_admin_count = 2
  #   @school_count = 2
  #   @customer_count = 10 # Students per school
  #   @teacher_count = 3
  #   @classroom_count = 3
  #   @class_count = 3
  #   @course_count = 4

  #   seed
  # end

  # def seed
  #   puts "\n\n🏫 Starting School Seeding..."
  #   puts "========================================================="

  #   # --- 1. Create School Owners (User) ---
  #   puts "Creating 1 school owner..."
  #   @company_business_type = User.COMPANY_GROUP_BUSINESS_TYPES[:school]
  #   @school_owner = Seed::UserService.create(email: @owner_email, company_business_type: @company_business_type)

  #   #--- 2. Create Schools (Company) ---
  #   puts "Creating #{@school_count} schools..."
  #   @school_count.times do |i|
  #     school = Seed::CompanyService.create(
  #       user: @school_owner,
  #       name: "School #{i + 1}",
  #       description: "Description for School #{i + 1}",
  #       parent_company: nil
  #     )
  #     @schools << school
  #   end
  #   puts "Created #{@schools.count} schools."
    
  #   # --- 3. Create Payment Method Appointments for Schools (Companies) ---
  #   @schools.each do |school|
  #     2.times do
  #       Seed::PaymentMethodAppointmentService.create(
  #         company: school
  #       )
  #     end
  #   end
  #   puts "Appointed some payment methods to each school."

  #   # --- 4. Create School Roles + Custom Roles ---
  #   SCHOOL_ROLES.each do |role_name|
  #     @schools.each do |school|
  #       Seed::RoleService.create(
  #         company: school,
  #         name: role_name,
  #         description: "#{role_name} role for #{school.name}"
  #       )
  #     end
  #   end

  #   # --- 5. Create Employees for Each School (Company) ---
  #   @schools.each do |school|
  #     puts "Creating employees for #{school.name}..."
  #     EMPLOYEE_COUNTS.each do |role_name, count|
  #       count.times do |i|
  #         user = Seed::UserService.create(parent_user: @school_owner, email: "#{role_name.downcase}_#{i + 1}_#{school.id}@example.com")
  #         employee = Seed::EmployeeService.create(
  #           user: user,
  #           company: school
  #         )
  #         employee.attach_tag(name: "Employee #{employee.id} Tag")
  #         employee.attach_role(role_name)
  #         @employees << employee
  #       end
  #     end
  #     puts "Created #{@employees.count} employees for #{school.name}."
  #   end

  #   # --- 6. Create Customers (Students) for Each School (Company) ---
  #   @schools.each do |school|
  #     puts "Creating customers (students) for #{school.name}..."
  #     CUSTOMER_COUNTS.each do |role_name, count|
  #       count.times do |i|
  #         user = Seed::UserService.create(parent_user: @school_owner, email: "student_#{i + 1}_#{school.id}@example.com")
  #         customer = Seed::CustomerService.create(
  #           user: user,
  #           company: school
  #         )
  #         customer.attach_tag(name: "Customer #{customer.id} Tag")
  #         customer.attach_role(role_name)
  #         @customers << customer
  #       end
  #     end
  #     puts "Created #{@customers.count} customers (students) for #{school.name}."
  #   end

  #   # --- 7. Create Classes (Customer Groups) and Enroll Students (Customers) ---
  #   @schools.each do |school|
  #     puts "Enrolling students in classes for #{school.name}..."
  #     @class_count.times do |i|
  #       klass = Seed::CustomerGroupService.create(
  #         company: school,
  #         name: "Class #{i + 1} - #{school.name}",
  #         description: "Description for Class #{i + 1} in #{school.name}"
  #       )
  #       klass.attach_tag(name: "Class #{klass.id} Tag")
  #       # Enroll 5 random students per class
  #       students = @customers.select { |c| c.company_id == school.id }
  #       enrolled_students = students.sample(5)
  #       enrolled_students.each do |student|
  #         Seed::CustomerGroupAppointmentService.create(
  #           customer_group: klass,
  #           appoint_to: student
  #         )
  #       end
  #       @classes << klass
  #     end
  #     puts "Created #{@classes.count} classes and enrolled students for #{school.name}."

  #     # --- 8. Enroll Classes (Customer Groups) in Courses (Services) ---
  #     puts "Creating courses and enrolling classes for #{school.name}..."
  #     @course_count.times do |i|
  #       course = Seed::ServiceService.create(
  #         company: school,
  #         name: "Course #{i + 1} - #{school.name}",
  #         description: "Description for Course #{i + 1} in #{school.name}"
  #       )
  #       course.attach_tag(name: "Course #{course.id} Tag")
  #       # Enroll all classes in this course
  #       @classes.each do |klass|
  #         Seed::ServiceAppointmentService.create(
  #           service: course,
  #           appoint_to: klass
  #         )
  #       end
  #       @courses << course
  #     end
  #     puts "Created #{@courses.count} courses for #{school.name}."

  #     # --- 9. Assign Teachers (Employees) to Courses (Services) ---
  #     puts "Assigning teachers to courses for #{school.name}..."
  #     teachers = @employees.select { |e| e.has_role?('Teacher') && e.company_id == school.id }
  #     @courses.each do |course|
  #       assigned_teacher = teachers.sample
  #       Seed::ServiceAppointmentService.create(
  #         service: course,
  #         appoint_to: assigned_teacher
  #       )
  #     end
  #     puts "Assigned teachers to courses for #{school.name}."

  #     # --- 10. Create some Rooms (Facilities) for Each School ---
  #     puts "Creating rooms for #{school.name}..."
  #     5.times do |i|
  #       room = Seed::FacilityService.create(
  #         company: school,
  #         name: "Room #{i + 1} - #{school.name}",
  #         description: "Description for Room #{i + 1} in #{school.name}"
  #       )
  #       room.attach_tag(name: "Room #{room.id} Tag")
  #     end
  #     puts "Created some rooms for #{school.name}."


  #   end
















  #   puts "\n========================================================="
  #   puts "🏫 School Seeding Complete!"
  #   puts "========================================================="
  #   true
  # end
end
