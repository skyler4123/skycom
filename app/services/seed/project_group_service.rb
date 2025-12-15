# This service seeds the database with ProjectGroup records. Each group is
# associated with a Company and can be used to organize projects.

class Seed::ProjectGroupService
  # Configuration for the number of project groups to create per company
  GROUPS_PER_COMPANY = 3

  def self.run
    puts "Seeding ProjectGroup records..."

    # Get enum keys once before the loop for efficiency.
    statuses = ProjectGroup.statuses.keys
    business_types = ProjectGroup.business_types.keys

    Company.all.each do |company|
      GROUPS_PER_COMPANY.times do |i|
        # Randomly decide whether to mark the record as discarded
        should_discard = rand(10) == 0 # 10% chance of being discarded

        ProjectGroup.create!(
          company: company,
          name: "#{Faker::App.name} Project Group #{i + 1}",
          description: "A group for projects related to #{Faker::Commerce.department}.",
          code: "PROJ-G-#{company.id}-#{SecureRandom.hex(3).upcase}",
          status: statuses.sample,
          business_type: business_types.sample,
          # Set a past timestamp for discarded_at if the record is to be soft-deleted
          discarded_at: should_discard ? Time.zone.now - rand(1..180).days : nil
        )
      end
    end

    puts "Successfully created #{ProjectGroup.count} ProjectGroup records."
  end

  def self.create(
    company:,
    name: "#{Faker::App.name} Project Group",
    description: "A group for projects related to #{Faker::Commerce.department}.",
    code: nil,
    status: nil,
    business_type: nil,
    discarded_at: nil
  )
    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil

    ProjectGroup.create!(
      company: company,
      name: name,
      description: description,
      code: code || "PROJ-G-#{company.id}-#{SecureRandom.hex(3).upcase}",
      status: status || ProjectGroup.statuses.keys.sample,
      business_type: business_type || ProjectGroup.business_types.keys.sample,
      discarded_at: discarded_at
    )
  end
end
