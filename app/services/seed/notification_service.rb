class Seed::NotificationService
  def self.create(
    company:,
    branch: nil,
    notification_group: nil,
    name: nil,
    description: nil,
    code: nil,
    lifecycle_status: nil,
    workflow_status: nil,
    business_type: nil,
    discarded_at: nil
  )
    raise "Cannot create a notification: No company provided." if company.nil?

    branch ||= notification_group.branch if notification_group

    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil

    Notification.create!(
      company: company,
      branch: branch,
      notification_group: notification_group,
      name: name || "Notification #{Faker::Lorem.sentence(word_count: 3)}",
      description: description || Faker::Lorem.sentence(word_count: 10),
      code: code || "NOTIF-#{branch&.id || 'X'}-#{notification_group&.id || 'X'}-#{SecureRandom.hex(2).upcase}",
      lifecycle_status: lifecycle_status || Notification.lifecycle_statuses.keys.sample,
      workflow_status: workflow_status || Notification.workflow_statuses.keys.sample,
      business_type: business_type || Notification.business_types.keys.sample,
      discarded_at: discarded_at
    )
  end
end
