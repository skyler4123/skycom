# This service seeds the database with NotificationGroup records. Each group is
# associated with a Company and can be used to organize notifications.

class Seed::NotificationGroupService
  # Configuration for the number of notification groups to create per company
  GROUPS_PER_COMPANY = 3

  def self.run
    puts "Seeding NotificationGroup records..."

    # Get enum keys once before the loop for efficiency.
    statuses = NotificationGroup.statuses.keys
    business_types = NotificationGroup.business_types.keys

    Company.all.each do |company|
      GROUPS_PER_COMPANY.times do |i|
        # Randomly decide whether to mark the record as discarded
        should_discard = rand(10) == 0 # 10% chance of being discarded

        NotificationGroup.create!(
          company: company,
          name: "#{Faker::App.name} Notifications #{i + 1}",
          description: "A group for #{Faker::Marketing.buzzwords} notifications.",
          code: "NOTIF-G-#{company.id}-#{SecureRandom.hex(3).upcase}",
          status: statuses.sample,
          business_type: business_types.sample,
          # Set a past timestamp for discarded_at if the record is to be soft-deleted
          discarded_at: should_discard ? Time.zone.now - rand(1..180).days : nil
        )
      end
    end

    puts "Successfully created #{NotificationGroup.count} NotificationGroup records."
  end

  def self.create(
    company:,
    name: "#{Faker::App.name} Notifications",
    description: "A group for #{Faker::Marketing.buzzwords} notifications.",
    code: nil,
    status: nil,
    business_type: nil,
    discarded_at: nil
  )
    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil

    NotificationGroup.create!(
      company: company,
      name: name,
      description: description,
      code: code || "NOTIF-G-#{company.id}-#{SecureRandom.hex(3).upcase}",
      status: status || NotificationGroup.statuses.keys.sample,
      business_type: business_type || NotificationGroup.business_types.keys.sample,
      discarded_at: discarded_at
    )
  end
end