# This service seeds the database with Customer records. Each customer is
# associated with a Company. It uses enums from the Customer model and
# simulates soft deletion for a portion of the records.

class Seed::CustomerService
  # Configuration for the number of customers to create per company
  CUSTOMERS_PER_COMPANY = 10

  def self.run
    # Get enum keys once before the loop for efficiency.
    statuses = Customer.statuses.keys
    business_types = Customer.business_types.keys

    Company.all.each do |company|
      CUSTOMERS_PER_COMPANY.times do
        # Randomly decide whether to mark the record as discarded
        should_discard = rand(10) == 0 # 10% chance of being discarded

        Customer.create!(
          company: company,
          name: Faker::Name.name,
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