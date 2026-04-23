class Seed::TaskService
  def self.new(
    company:,
    task_group: TaskGroup.all.sample,
    branch: nil,
    name: "#{Faker::Verb.base.capitalize} the #{Faker::Hacker.noun}",
    description: nil,
    code: nil,
    currency_code: nil,
    lifecycle_status: nil,
    workflow_status: nil,
    business_type: nil,
    discarded_at: nil
  )
    raise "Cannot create a task: No task groups exist." if task_group.nil?

    company ||= task_group.company
    branch ||= task_group.branch

    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil

    Task.new(
      company: company,
      task_group: task_group,
      branch: branch,
      name: name,
      description: description || "Task for group '#{task_group.name}'.",
      code: code || "TASK-#{company.id}-#{task_group.id}-#{SecureRandom.hex(2).upcase}",
      currency_code: currency_code || Task.currency_codes.keys.sample,
      lifecycle_status: lifecycle_status || Task.lifecycle_statuses.keys.sample,
      workflow_status: workflow_status || Task.workflow_statuses.keys.sample,
      business_type: business_type || Task.business_types.keys.sample,
      discarded_at: discarded_at
    )
  end

  def self.create(...)
    task = new(...)
    task.save!
    task
  end
end
