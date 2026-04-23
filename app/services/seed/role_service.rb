class Seed::RoleService
  def self.new(
    company:,
    name:,
    description: Faker::Lorem.sentence(word_count: 8),
    business_type: Role.business_types.keys.sample,
    discarded_at: nil
  )
    should_discard = rand(8) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..60).days : nil

    Role.new(
      company: company,
      name: name,
      description: description,
      business_type: business_type,
      discarded_at: discarded_at
    )
  end

  def self.create(...)
    role = new(...)
    role.save!
    role
  end
end
