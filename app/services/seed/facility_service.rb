# This service seeds the database with Facility records, ensuring each facility
# is associated with an existing Company. It uses enums if they are defined
# in the Facility model and simulates soft deletion for a portion of the records.

class Seed::FacilityService
  # Configuration for the number of facilities to create per company
  FACILITIES_PER_COMPANY = 3

  def self.run
    # It's efficient to get enum keys once before the loop, if they exist.
    # If the Facility model does not have these enums, these lines will raise an error.
    # You can replace them with static arrays like %w[active inactive] if needed.
    statuses = Facility.statuses.keys
    business_types = Facility.business_types.keys

    Company.all.each do |company|
      FACILITIES_PER_COMPANY.times do |i|
        # Randomly decide whether to mark the record as discarded
        should_discard = rand(10) == 0 # 10% chance of being discarded

        Facility.create!(
          company: company,
          name: "#{company.name} Facility #{i + 1}",
          description: Faker::Lorem.sentence(word_count: 10),
          status: statuses.sample,
          business_type: business_types.sample,
          # Set a past timestamp for discarded_at if the record is to be soft-deleted
          discarded_at: should_discard ? Time.zone.now - rand(1..180).days : nil
        )
      end
    end
  end
end