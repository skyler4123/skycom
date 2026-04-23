class Seed::PurchaseService
  def self.create(
    company:,
    branch: nil,
    name: nil,
    description: nil,
    code: nil,
    status: nil,
    business_type: nil,
    discarded_at: nil
  )
    raise "Cannot create purchase: No company provided." if company.nil?

    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil

    Purchase.create!(
      company: company,
      branch: branch,
      name: name || "Purchase #{Faker::Lorem.sentence(word_count: 3)}",
      description: description || Faker::Lorem.sentence(word_count: 10),
      code: code || "PUR-#{SecureRandom.hex(4).upcase}",
      status: status || Purchase.statuses.keys.sample,
      business_type: business_type || Purchase.business_types.keys.sample,
      discarded_at: discarded_at
    )
  end
end
