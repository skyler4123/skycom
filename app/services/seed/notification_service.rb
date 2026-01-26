# This service seeds the database with Notification records. Each notification is
# associated with a NotificationGroup and a Company.

class Seed::NotificationService
  def self.create(
    notification_group: NotificationGroup.all.sample,
    name: nil,
    description: nil,
    code: nil,
    lifecycle_status: Notification.lifecycle_statuses.keys.sample,
    workflow_status: Notification.workflow_statuses.keys.sample,
    business_type: Notification.business_types.keys.sample,
    discarded_at: nil
  )
    raise "Cannot create a notification: No notification groups exist." if notification_group.nil?
    company = notification_group.company

    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil

    Notification.create!(
      company: company,
      notification_group: notification_group,
      name: name || "Notification for #{company.name}",
      description: description || "A notification for group '#{notification_group.name}'.",
      code: code || "NOTIF-#{company.id}-#{notification_group.id}-#{SecureRandom.hex(2).upcase}",
      lifecycle_status: lifecycle_status,
      workflow_status: workflow_status,
      business_type: business_type,
      discarded_at: discarded_at
    )
  end
end
