# This service seeds the database with Role records, ensuring each role
# is associated with an existing Branch. It uses the enums defined in the Role model
# and simulates soft deletion.

class Seed::RoleService
  def self.create(
    company:,
    name:,
    description: Faker::Lorem.sentence(word_count: 8),
    business_type: Role.business_types.keys.sample,
    discarded_at: nil
  )
    should_discard = rand(8) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..60).days : nil

    Role.create!(
      company: company,
      name: name,
      description: description,
      business_type: business_type,
      discarded_at: discarded_at
    )
  end
end
