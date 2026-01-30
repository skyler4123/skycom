# This service seeds the database with Invoice records. Each invoice is
# associated with an existing Order. It uses enums from the Invoice model
# and simulates soft deletion for a portion of the records.

class Seed::InvoiceService
  def self.create(
    order:,
    name: nil,
    description: Faker::Lorem.sentence(word_count: 10),
    currency_code: Invoice.currencies.keys.sample,
    number: nil,
    total: nil,
    due_date: Faker::Date.forward(days: 30),
    lifecycle_status: Invoice.lifecycle_statuses.keys.sample,
    workflow_status: Invoice.workflow_statuses.keys.sample,
    business_type: Invoice.business_types.keys.sample,
    discarded_at: nil
  )
    raise "Cannot create an invoice: No orders exist." if order.nil?

    calculated_total = order.order_appointments.sum(:total_price)
    total ||= (calculated_total > 0 ? calculated_total : Faker::Commerce.price(range: 50..2000.0))

    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil
    name ||= "Invoice for Order ##{order.id}"
    number ||= "INV-#{order.id}-#{SecureRandom.hex(4).upcase}"

    Invoice.create!(
      order: order,
      name: name,
      description: description,
      currency_code: currency,
      number: number,
      total: total,
      due_date: due_date,
      lifecycle_status: lifecycle_status,
      workflow_status: workflow_status,
      business_type: business_type,
      discarded_at: discarded_at
    )
  end
end
