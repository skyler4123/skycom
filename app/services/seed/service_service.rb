# This service seeds the database with Service records, ensuring each service
# is associated with an existing Company. It uses enums defined in the Service
# model and simulates soft deletion for a portion of the records.

class Seed::ServiceService

  # Configuration for the number of services to create per company
  SERVICES_PER_COMPANY = 3

  def self.run
    # It's efficient to get enum keys once before the loop.
    statuses = Service.statuses.keys
    business_types = Service.business_types.keys

    puts "Seeding Service records..."

    Company.all.each do |company|
      SERVICES_PER_COMPANY.times do |i|
        # Randomly decide whether to mark the record as discarded
        should_discard = rand(10) == 0 # 10% chance of being discarded

        Service.create!(
          company: company,
          name: "#{company.name} Service #{i + 1}",
          description: Faker::Lorem.sentence(word_count: 10),
          status: statuses.sample,
          business_type: business_types.sample,
          # Set a past timestamp for discarded_at if the record is to be soft-deleted
          discarded_at: should_discard ? Time.zone.now - rand(1..180).days : nil
        )
      end
    end

    puts "Successfully created #{Service.count} Service records."
  end
end