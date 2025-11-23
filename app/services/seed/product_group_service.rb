# This service seeds the database with ProductGroup records. Each group is
# associated with a Company and can be used to organize products.

class Seed::ProductGroupService
  # Configuration for the number of product groups to create per company
  GROUPS_PER_COMPANY = 3

  def self.run
    puts "Seeding ProductGroup records..."

    # Get enum keys once before the loop for efficiency.
    statuses = ProductGroup.statuses.keys
    business_types = ProductGroup.business_types.keys

    Company.all.each do |company|
      GROUPS_PER_COMPANY.times do |i|
        # Randomly decide whether to mark the record as discarded
        should_discard = rand(10) == 0 # 10% chance of being discarded

        ProductGroup.create!(
          company: company,
          name: "#{Faker::Commerce.department} Group #{i + 1}",
          description: "A group for products in the #{Faker::Commerce.material} category.",
          code: "PG-#{company.id}-#{SecureRandom.hex(3).upcase}",
          status: statuses.sample,
          business_type: business_types.sample,
          # Set a past timestamp for discarded_at if the record is to be soft-deleted
          discarded_at: should_discard ? Time.zone.now - rand(1..180).days : nil
        )
      end
    end

    puts "Successfully created #{ProductGroup.count} ProductGroup records."
  end

  def self.create(
    company: Company.all.sample,
    name: "#{Faker::Commerce.department} Group",
    description: "A group for products in the #{Faker::Commerce.material} category.",
    code: nil,
    status: nil,
    business_type: nil,
    discarded_at: nil
  )
    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil

    ProductGroup.create!(
      company: company,
      name: name,
      description: description,
      code: code || "PG-#{company.id}-#{SecureRandom.hex(3).upcase}",
      status: status || ProductGroup.statuses.keys.sample,
      business_type: business_type || ProductGroup.business_types.keys.sample,
      discarded_at: discarded_at
    )
  end
end