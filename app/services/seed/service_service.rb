class Seed::ServiceService
  def self.create(
    company_group:,
    company:,
    name: nil,
    description: Faker::Lorem.sentence(word_count: 10),
    status: nil,
    business_type: nil,
    discarded_at: nil
  )
    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil

    Service.create!(
      company_group: company_group,
      company: company,
      name: name || "#{company.name} Service",
      description: description,
      status: status || Service.statuses.keys.sample,
      business_type: business_type || Service.business_types.keys.sample,
      discarded_at: discarded_at
    )
  end
end
