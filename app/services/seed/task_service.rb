# This service seeds the database with Task records. Each task is
# associated with a TaskGroup and a Branch.

class Seed::TaskService
  def self.create(
    task_group: TaskGroup.all.sample,
    name: "#{Faker::Verb.base.capitalize} the #{Faker::Hacker.noun}",
    description: nil,
    code: nil,
    currency_code: nil,
    status: nil,
    business_type: nil,
    discarded_at: nil
  )
    raise "Cannot create a task: No task groups exist." if task_group.nil?
    company = task_group.company

    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil

    Task.create!(
      branch: branch,
      task_group: task_group,
      name: name,
      description: description || "Task for group '#{task_group.name}'.",
      code: code || "TASK-#{branch.id}-#{task_group.id}-#{SecureRandom.hex(2).upcase}",
      currency_code: currency || Task.currency_codes.keys.sample,
      status: status || Task.statuses.keys.sample,
      business_type: business_type || Task.business_types.keys.sample,
      discarded_at: discarded_at
    )
  end
end
