# This service seeds the database with Customer records. Each customer is
# associated with a Branch. It uses enums from the Customer model and
# simulates soft deletion for a portion of the records.

class Seed::CustomerService
  def self.create(
    company:,
    branch: nil,
    user: nil,
    email: "customer_#{SecureRandom.hex}@gmail.com",
    name: Faker::Name.name,
    description: Faker::Lorem.sentence(word_count: 10),
    lifecycle_status: Customer.lifecycle_statuses.keys.sample,
    workflow_status: Customer.workflow_statuses.keys.sample,
    business_type: Customer.business_types.keys.sample,
    discarded_at: nil
  )
    Customer.create!(
      company: company,
      branch: branch,
      user: user,
      name: name,
      email: email,
      description: description,
      lifecycle_status: lifecycle_status,
      workflow_status: workflow_status,
      business_type: business_type,
      discarded_at: discarded_at
    )
  end
end
