# This service seeds the database with ProductBrand records. Unlike other
# seeders, these are not tied to a specific company. It uses enums defined
# in the ProductBrand model and simulates soft deletion for some records.

class Seed::ProductBrandService
  def self.create(
    name: Faker::Commerce.brand,
    description: Faker::Lorem.sentence(word_count: 8),
    status: nil,
    business_type: nil,
    discarded_at: nil
  )
    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil
    status ||= ProductBrand.statuses.keys.sample
    business_type ||= ProductBrand.business_types.keys.sample

    ProductBrand.create!(
      name: name,
      description: description,
      status: status,
      business_type: business_type,
      discarded_at: discarded_at
    )
  end
end
