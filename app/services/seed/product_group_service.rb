# This service seeds the database with ProductGroup records. Each group is
# associated with a Company and can be used to organize products.

class Seed::ProductGroupService
  def self.create(
    branch:,
    name: "#{Faker::Commerce.department} Group",
    description: "A group for products in the #{Faker::Commerce.material} category.",
    code: nil,
    status: nil,
    business_type: nil,
    discarded_at: nil
  )
    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil
    code ||= "PG-#{branch.id}-#{SecureRandom.hex(3).upcase}"
    status ||= ProductGroup.statuses.keys.sample
    business_type ||= ProductGroup.business_types.keys.sample

    ProductGroup.create!(
      branch: branch,
      name: name,
      description: description,
      code: code,
      status: status,
      business_type: business_type,
      discarded_at: discarded_at
    )
  end
end
