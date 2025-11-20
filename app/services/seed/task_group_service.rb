# This service seeds the database with TaskGroup records. Each group is
# associated with a Company and can be used to organize tasks.

class Seed::TaskGroupService
  # Configuration for the number of task groups to create per company
  GROUPS_PER_COMPANY = 3

  def self.run
    puts "Seeding TaskGroup records..."

    # Get enum keys once before the loop for efficiency.
    statuses = TaskGroup.statuses.keys
    business_types = TaskGroup.business_types.keys

    Company.all.each do |company|
      GROUPS_PER_COMPANY.times do |i|
        # Randomly decide whether to mark the record as discarded
        should_discard = rand(10) == 0 # 10% chance of being discarded

        TaskGroup.create!(
          company: company,
          name: "#{Faker::Verb.base.capitalize} Tasks #{i + 1}",
          description: "A group for #{Faker::Hacker.ingverb} tasks.",
          code: "TG-#{company.id}-#{SecureRandom.hex(3).upcase}",
          status: statuses.sample,
          business_type: business_types.sample,
          # Set a past timestamp for discarded_at if the record is to be soft-deleted
          discarded_at: should_discard ? Time.zone.now - rand(1..180).days : nil
        )
      end
    end

    puts "Successfully created #{TaskGroup.count} TaskGroup records."
  end
end