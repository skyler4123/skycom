# This service seeds the database with Task records. Each task is
# associated with a TaskGroup and a Company.

class Seed::TaskService
  # Configuration for the number of tasks to create per task group
  TASKS_PER_GROUP = 5

  def self.run
    puts "Seeding Task records..."

    # Get enum keys once before the loop for efficiency.
    statuses = Task.statuses.keys
    business_types = Task.business_types.keys
    currencies = Task.currencies.keys

    TaskGroup.all.each do |task_group|
      company = task_group.company

      TASKS_PER_GROUP.times do |i|
        # Randomly decide whether to mark the record as discarded
        should_discard = rand(10) == 0 # 10% chance of being discarded

        Task.create!(
          company: company,
          task_group: task_group,
          name: "#{Faker::Verb.base.capitalize} the #{Faker::Hacker.noun}",
          description: "Task ##{i + 1} for group '#{task_group.name}'.",
          code: "TASK-#{company.id}-#{task_group.id}-#{SecureRandom.hex(2).upcase}",
          currency: currencies.sample,
          status: statuses.sample,
          business_type: business_types.sample,
          # Set a past timestamp for discarded_at if the record is to be soft-deleted
          discarded_at: should_discard ? Time.zone.now - rand(1..180).days : nil
        )
      end
    end

    puts "Successfully created #{Task.count} Task records."
  end
end