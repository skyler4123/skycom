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
    @school_owners = []
    @school_admin = []
    @schools = []
    @customers = [] # Mapping students to customers
    @teachers = []
    @classrooms = []
    @courses = []

    @school_owner_count = 2
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
    puts "Creating #{@school_owner_count} school owners..."
    @school_owner_count.times do |i|
      @school_owners << Seed::UserService.create(email: "school_owner_#{i + 1}@example.com")
    end



    puts "\n========================================================="
    puts "🏫 School Seeding Complete!"
    puts "========================================================="
    true
  end
end
