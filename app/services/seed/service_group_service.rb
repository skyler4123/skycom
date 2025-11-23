# This service seeds the database with ServiceGroup records. Each group is
# associated with a Company and can be used to organize services.

class Seed::ServiceGroupService
  # Configuration for the number of service groups to create per company
  GROUPS_PER_COMPANY = 3

  def self.run
    puts "Seeding ServiceGroup records..."

    # Get enum keys once before the loop for efficiency.
    statuses = ServiceGroup.statuses.keys
    business_types = ServiceGroup.business_types.keys

    Company.all.each do |company|
      GROUPS_PER_COMPANY.times do |i|
        # Randomly decide whether to mark the record as discarded
        should_discard = rand(10) == 0 # 10% chance of being discarded

        start_date = Faker::Date.between(from: 1.year.ago, to: Date.today)
        duration_in_days = rand(7..365)

        ServiceGroup.create!(
          company: company,
          name: "#{Faker::App.name} Service Group #{i + 1}",
          description: "A group for #{Faker::Company.bs} services.",
          code: "SG-#{company.id}-#{SecureRandom.hex(3).upcase}",
          status: statuses.sample,
          duration: duration_in_days,
          start_at: start_date.to_datetime,
          business_type: business_types.sample,
          # Set a past timestamp for discarded_at if the record is to be soft-deleted
          discarded_at: should_discard ? Time.zone.now - rand(1..180).days : nil
        )
      end
    end

    puts "Successfully created #{ServiceGroup.count} ServiceGroup records."
  end

  def self.create(
    company:,
    name: "#{Faker::App.name} Service Group",
    description: "A group for #{Faker::Company.bs} services.",
    code: nil,
    status: nil,
    duration: rand(7..365),
    start_at: Faker::Date.between(from: 1.year.ago, to: Date.today).to_datetime,
    business_type: nil,
    discarded_at: nil
  )
    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil

    ServiceGroup.create!(
      company: company,
      name: name,
      description: description,
      code: code || "SG-#{company.id}-#{SecureRandom.hex(3).upcase}",
      status: status || ServiceGroup.statuses.keys.sample,
      duration: duration,
      start_at: start_at,
      business_type: business_type || ServiceGroup.business_types.keys.sample,
      discarded_at: discarded_at
    )
  end
end