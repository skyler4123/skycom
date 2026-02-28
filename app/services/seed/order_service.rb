# This service seeds the database with Order records. Each order is associated
# with a Company and a Customer from that same branch. It uses enums from the
# Order model and simulates soft deletion for a portion of the records.

class Seed::OrderService
  def self.create(
    company:,
    branch: nil,
    customer: nil,
    name: Faker::Company.buzzword,
    description: Faker::Lorem.sentence(word_count: 15),
    currency_code: Order.currency_codes.keys.sample,
    lifecycle_status: Order.lifecycle_statuses.keys.sample,
    workflow_status: Order.workflow_statuses.keys.sample,
    business_type: Order.business_types.keys.sample,
    discarded_at: nil
  )
    Order.create!(
      company: company,
      branch: branch,
      customer: customer,
      name: name,
      description: description,
      currency_code: currency_code,
      lifecycle_status: lifecycle_status,
      workflow_status: workflow_status,
      business_type: business_type,
      discarded_at: discarded_at
    )
  end
end
