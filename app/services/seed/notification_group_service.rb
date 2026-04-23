class Seed::NotificationGroupService
  def self.new(
    branch:,
    name: "#{Faker::App.name} Notifications",
    description: "A group for #{Faker::Marketing.buzzwords} notifications.",
    code: nil,
    lifecycle_status: NotificationGroup.lifecycle_statuses.keys.sample,
    workflow_status: NotificationGroup.workflow_statuses.keys.sample,
    business_type: NotificationGroup.business_types.keys.sample,
    discarded_at: nil
  )
    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil
    code ||= "NOTIF-G-#{branch.id}-#{SecureRandom.hex(3).upcase}"

    NotificationGroup.new(
      branch: branch,
      name: name,
      description: description,
      code: code,
      lifecycle_status: lifecycle_status,
      workflow_status: workflow_status,
      business_type: business_type,
      discarded_at: discarded_at
    )
  end

  def self.create(...)
    group = new(...)
    group.save!
    group
  end
end
