# This service seeds the database with Notification records. Each notification is
# associated with a NotificationGroup and a Company.

class Seed::NotificationService
  # Configuration for the number of notifications to create per group
  NOTIFICATIONS_PER_GROUP = 5

  def self.run
    puts "Seeding Notification records..."

    # Get enum keys once before the loop for efficiency.
    statuses = Notification.statuses.keys
    business_types = Notification.business_types.keys

    NotificationGroup.all.each do |notification_group|
      company = notification_group.company

      NOTIFICATIONS_PER_GROUP.times do |i|
        # Randomly decide whether to mark the record as discarded
        should_discard = rand(10) == 0 # 10% chance of being discarded

        Notification.create!(
          company: company,
          notification_group: notification_group,
          name: "Notification ##{i + 1} for #{company.name}",
          description: "A notification for group '#{notification_group.name}'.",
          code: "NOTIF-#{company.id}-#{notification_group.id}-#{SecureRandom.hex(2).upcase}",
          status: statuses.sample,
          business_type: business_types.sample,
          # Set a past timestamp for discarded_at if the record is to be soft-deleted
          discarded_at: should_discard ? Time.zone.now - rand(1..180).days : nil
        )
      end
    end

    puts "Successfully created #{Notification.count} Notification records."
  end
end