# This service seeds the database with CartGroup records. Each group is
# associated with a Company and can be used to organize carts.

class Seed::CartGroupService
  # Configuration for the number of cart groups to create per company
  GROUPS_PER_COMPANY = 3

  def self.run
    puts "Seeding CartGroup records..."

    # Get enum keys once before the loop for efficiency.
    statuses = CartGroup.statuses.keys
    business_types = CartGroup.business_types.keys

    Company.all.each do |company|
      GROUPS_PER_COMPANY.times do |i|
        # Randomly decide whether to mark the record as discarded
        should_discard = rand(10) == 0 # 10% chance of being discarded

        CartGroup.create!(
          company: company,
          name: "#{Faker::Commerce.department} Carts #{i + 1}",
          description: "A group for carts related to #{Faker::Marketing.buzzwords}.",
          code: "CART-G-#{company.id}-#{SecureRandom.hex(3).upcase}",
          status: statuses.sample,
          business_type: business_types.sample,
          # Set a past timestamp for discarded_at if the record is to be soft-deleted
          discarded_at: should_discard ? Time.zone.now - rand(1..180).days : nil
        )
      end
    end

    puts "Successfully created #{CartGroup.count} CartGroup records."
  end
end