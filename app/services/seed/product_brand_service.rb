# This service seeds the database with ProductBrand records. Unlike other
# seeders, these are not tied to a specific company. It uses enums defined
# in the ProductBrand model and simulates soft deletion for some records.

class Seed::ProductBrandService
  # Configuration for the total number of product brands to create
  PRODUCT_BRANDS_TO_CREATE = 15

  def self.run
    ProductBrand.destroy_all

    # Get enum keys once before the loop for efficiency.
    statuses = ProductBrand.statuses.keys
    business_types = ProductBrand.business_types.keys

    puts "Seeding ProductBrand records..."

    PRODUCT_BRANDS_TO_CREATE.times do |index|
      # Randomly decide whether to mark the record as discarded
      should_discard = rand(10) == 0 # 10% chance of being discarded

      ProductBrand.create!(
        name: "#{Faker::Commerce.brand} #{index + 1}",
        description: Faker::Lorem.sentence(word_count: 8),
        status: statuses.sample,
        business_type: business_types.sample,
        # Set a past timestamp for discarded_at if the record is to be soft-deleted
        discarded_at: should_discard ? Time.zone.now - rand(1..180).days : nil
      )
    end

    puts "Successfully created #{ProductBrand.count} ProductBrand records."
  end

  def self.create(
    name: Faker::Commerce.brand,
    description: Faker::Lorem.sentence(word_count: 8),
    status: nil,
    business_type: nil,
    discarded_at: nil
  )
    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil

    ProductBrand.create!(
      name: name,
      description: description,
      status: status || ProductBrand.statuses.keys.sample,
      business_type: business_type || ProductBrand.business_types.keys.sample,
      discarded_at: discarded_at
    )
  end
end
