class Seed::SchoolService

  # Define the standard roles to be created for each school
  SCHOOL_ROLES = %w[Principal Admin Teacher Student Accountant Cleaner Guard].freeze

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
      @school_owners << Seed::UserService.create(username: "school_owner_#{i + 1}")
    end

    # --- 2. Create Schools (Companies) for each Owner ---
    @school_owners.each do |owner|
      puts "Creating #{@school_count} schools for owner #{owner.username}..."
      @school_count.times do |j|
        base_name = "#{Faker::University.name} #{j + 1}"
        school = owner.companies.create!(
          # Core Attributes
          name: base_name,
          description: "A fine educational institution.",

          # Enums
          business_type: :school,
          status: :active,
          ownership_type: :privately_held, # Corrected from :private
          currency: Company.currencies.keys.sample,

          # Administrative Fields
          registration_number: Faker::Company.ein,
          employee_count: rand(20..200),

          # Contact & Address Fields
          address_line_1: Faker::Address.street_address,
          city: Faker::Address.city,
          postal_code: Faker::Address.postcode,
          country: Faker::Address.country,
          email: Faker::Internet.email(name: "info.#{base_name.parameterize}"),
          phone_number: Faker::PhoneNumber.phone_number,
          website: Faker::Internet.url(host: "#{base_name.parameterize}.edu"),

          # Operational Fields
          fiscal_year_end_month: Company.fiscal_year_end_months.keys.sample
        )
        @schools << school

        # --- 3. Create Roles for each School ---
        puts "  Creating roles for #{school.name}..."
        SCHOOL_ROLES.each do |role_name|
          # Cycle through the available business_types for variety
          school.roles.create!(
            name: role_name,
            description: "The #{role_name} role for managing school operations.",
            code: "ROLE-#{school.id.to_s.first(4)}-#{role_name.upcase}",
            status: :active,
            business_type: Role.business_types.keys.sample # Use a valid business_type
          )
        end
      end
    end

    puts "\n========================================================="
    puts "🏫 School Seeding Complete!"
    puts "========================================================="
    true
  end
end
