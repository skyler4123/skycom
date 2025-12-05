# This service seeds the database with Product records. Each product is
# associated with a Company and may optionally be linked to a ProductBrand.
# It uses enums from the Product model and simulates soft deletion for some records.

class Seed::ProductService
  def self.create(
    company_group:,
    company: nil,
    brand: (Brand.all + [nil]).sample,
    name: Faker::Commerce.product_name,
    description: Faker::Lorem.sentence(word_count: 12),
    price: nil,
    status: nil,
    business_type: nil,
    discarded_at: nil
  )
    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil

    Product.create!(
      company_group: company_group,
      company: company,
      brand: brand,
      name: name,
      description: description,
      price: price || Faker::Commerce.price(range: 50..2000.0),
      status: status || Product.statuses.keys.sample,
      business_type: business_type || Product.business_types.keys.sample,
      discarded_at: discarded_at
    )
  end
end