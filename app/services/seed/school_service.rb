class Seed::SchoolService

  def initialize
    @school_owner = []
    @school_admin = []
    @schools = []
    @students = []
    @teachers = []
    @classrooms = []
    @courses = []

    @school_owner_count = 2
    @school_admin_count = 3
    @school_count = 3
    @student_count = 10
    @teacher_count = 5
    @classroom_count = 3
    @course_count = 4

    seed
  end

  def seed
    puts "\n\n🏫 Starting School Seeding..."
    puts "========================================================="

    
    @school_owner_count.times do |index|
      @school_owner.push(Seed::UserService.create(username: "school_owner", index: index))
    end

    




    puts "\n========================================================="
    puts "🏫 School Seeding Complete!"
    puts "========================================================="
    true
  end

end
