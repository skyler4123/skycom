# This service seeds the database with ProductGroup records. Each group is
# associated with a Company and can be used to organize products.

class Seed::ProductGroupService
  def self.create(
    company:,
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
