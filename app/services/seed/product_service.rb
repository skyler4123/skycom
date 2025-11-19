# This service seeds the database with Product records. Each product is
# associated with a Company and may optionally be linked to a ProductBrand.
# It uses enums from the Product model and simulates soft deletion for some records.

class Seed::ProductService
  # Configuration for the number of products to create per company
  PRODUCTS_PER_COMPANY = 5

  def self.run
    # Get enum keys and product brand IDs once before the loop for efficiency.
    statuses = Product.statuses.keys
    business_types = Product.business_types.keys
    # Include nil to allow for products without a brand
    product_brand_ids = ProductBrand.pluck(:id) + [nil]

    Company.all.each do |company|
      PRODUCTS_PER_COMPANY.times do |i|
        # Randomly decide whether to mark the record as discarded
        should_discard = rand(10) == 0 # 10% chance of being discarded

        Product.create!(
          company: company,
          product_brand_id: product_brand_ids.sample,
          name: "#{Faker::Commerce.product_name} #{i + 1}",
          description: Faker::Lorem.sentence(word_count: 12),
          status: statuses.sample,
          business_type: business_types.sample,
          # Set a past timestamp for discarded_at if the record is to be soft-deleted
          discarded_at: should_discard ? Time.zone.now - rand(1..180).days : nil
        )
      end
    end
  end
end