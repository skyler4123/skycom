class Seed::SchoolService

  # Define the standard roles to be created for each school
  SCHOOL_ROLES = %w[Principal Admin Teacher Student Accountant Cleaner Guard].freeze

  # Define the number of employees to create for each role
  EMPLOYEE_ROLES = {
    'Principal' => 1,
    'Admin' => 2,
    'Teacher' => 5,
    'Accountant' => 2,
    'Cleaner' => 3,
    'Guard' => 3
  }.freeze

  def initialize
    @school_owner = nil
    @school_admin = []
    @schools = []
    @customers = [] # Mapping students to customers
    @teachers = []
    @classrooms = []
    @courses = []

    @school_admin_count = 3
    @school_count = 3
    @customer_count = 10 # Students per school
    @teacher_count = 5
    @classroom_count = 3
    @course_count = 4

    seed
  end

  def seed
    puts "\n\n🏫 Starting School Seeding..."
    puts "========================================================="

    # --- 1. Create School Owners ---
    puts "Creating 1 school owner..."
    @school_owner = Seed::UserService.create(email: "school_owner_1@example.com")

    #--- 2. Create Schools ---
    puts "Creating #{@school_count} schools..."
    @school_count.times do |i|
      school = Seed::CompanyService.create(
        user: @school_owner,
        name: "School #{i + 1}",
        description: "Description for School #{i + 1}",
        parent_company: nil
      )
      @schools << school
    end
    puts "Created #{@schools.count} schools."
    
    # --- 3. Create School Roles ---
    SCHOOL_ROLES.each do |role_name|
      @schools.each do |school|
        Seed::RoleService.create(
          company: school,
          name: role_name,
          description: "#{role_name} role for #{school.name}"
        )
      end
    end

    puts "\n========================================================="
    puts "🏫 School Seeding Complete!"
    puts "========================================================="
    true
  end
end
