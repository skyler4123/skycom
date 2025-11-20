# This service seeds the database with Project records. Each project is
# associated with a ProjectGroup and a Company.

class Seed::ProjectService
  # Configuration for the number of projects to create per project group
  PROJECTS_PER_GROUP = 5

  def self.run
    puts "Seeding Project records..."

    # Get enum keys once before the loop for efficiency.
    statuses = Project.statuses.keys
    business_types = Project.business_types.keys

    ProjectGroup.all.each do |project_group|
      company = project_group.company

      PROJECTS_PER_GROUP.times do |i|
        # Randomly decide whether to mark the record as discarded
        should_discard = rand(10) == 0 # 10% chance of being discarded

        Project.create!(
          company: company,
          project_group: project_group,
          name: "#{Faker::App.name} Project #{i + 1}",
          description: "Project ##{i + 1} for group '#{project_group.name}'.",
          code: "PROJ-#{company.id}-#{project_group.id}-#{SecureRandom.hex(2).upcase}",
          status: statuses.sample,
          business_type: business_types.sample,
          # Set a past timestamp for discarded_at if the record is to be soft-deleted
          discarded_at: should_discard ? Time.zone.now - rand(1..180).days : nil
        )
      end
    end

    puts "Successfully created #{Project.count} Project records."
  end
end