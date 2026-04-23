class Seed::OrderService
  def self.new(
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
    Order.new(
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

  def self.create(...)
    order = new(...)
    order.save!
    order
  end
end
