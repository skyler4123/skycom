# This service seeds the database with Customer records. Each customer is
# associated with a Company. It uses enums from the Customer model and
# simulates soft deletion for a portion of the records.

class Seed::CustomerService
  def self.create(
    company_group:,
    company:,
    user: nil,
    name: Faker::Name.name,
    description: Faker::Lorem.sentence(word_count: 10),
    status: nil,
    business_type: nil,
    discarded_at: nil
  )
    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil

    Customer.create!(
      company_group: company_group,
      company: company,
      user: user,
      name: name,
      description: description,
      status: status || Customer.statuses.keys.sample,
      business_type: business_type || Customer.business_types.keys.sample,
      discarded_at: discarded_at
    )
  end
end