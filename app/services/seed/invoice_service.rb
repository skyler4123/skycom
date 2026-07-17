class Seed::InvoiceService
  def self.new(
    order:,
    company: nil,
    branch: nil,
    name: nil,
    description: Faker::Lorem.sentence(word_count: 10),
    currency: Invoice.currencies.keys.sample,
    code: nil,
    price_cents: nil,
    due_date: Faker::Date.forward(days: 30),
    lifecycle_status: Invoice.lifecycle_statuses.keys.sample,
    workflow_status: Invoice.workflow_statuses.keys.sample,
    business_type: Invoice.business_types.keys.sample,
    discarded_at: nil
  )
    raise "Cannot create an invoice: No orders exist." if order.nil?

    company ||= order.company
    branch ||= order.branch

    calculated_total_cents = (order.order_appointments.sum(:total_price) * 100).to_i
    price_cents ||= (calculated_total_cents > 0 ? calculated_total_cents : Faker::Commerce.price(range: 50..2000.0) * 100).to_i

    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil
    name ||= "Invoice for Order ##{order.id}"
    code ||= "INV-#{order.id}-#{SecureRandom.hex(4).upcase}"

    Invoice.new(
      order: order,
      company: company,
      branch: branch,
      name: name,
      description: description,
      currency: currency,
      code: code,
      price_cents: price_cents,
      due_date: due_date,
      lifecycle_status: lifecycle_status,
      workflow_status: workflow_status,
      business_type: business_type,
      discarded_at: discarded_at
    )
  end

  def self.create(...)
    invoice = new(...)
    invoice.save!
    invoice
  end
end
