# This service seeds the database with Order records. Each order is associated
# with a Company and a Customer from that same company. It uses enums from the
# Order model and simulates soft deletion for a portion of the records.

class Seed::OrderService
  def self.create(
    company_group:,
    company: nil,
    customer: nil,
    name: nil,
    description: Faker::Lorem.sentence(word_count: 15),
    currency: Faker::Currency.code,
    lifecycle_status: nil,
    workflow_status: nil,
    business_type: nil,
    discarded_at: nil
  )
    customer ||= company.customers.sample
    raise "Cannot create an order: Company '#{company.name}' has no customers." if customer.nil?

    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil

    Order.create!(
      company_group: company_group,
      company: company,
      customer: customer,
      name: name || "Order for #{customer.name}",
      description: description,
      currency: currency,
      lifecycle_status: lifecycle_status || Order.lifecycle_statuses.keys.sample,
      workflow_status: workflow_status || Order.workflow_statuses.keys.sample,
      business_type: business_type || Order.business_types.keys.sample,
      discarded_at: discarded_at
    )
  end
end
