class Seed::InvoiceService
  def self.new(
    order:,
    company: nil,
    branch: nil,
    name: nil,
    description: Faker::Lorem.sentence(word_count: 10),
    currency_code: Invoice.currency_codes.keys.sample,
    number: nil,
    total_price: nil,
    due_date: Faker::Date.forward(days: 30),
    lifecycle_status: Invoice.lifecycle_statuses.keys.sample,
    workflow_status: Invoice.workflow_statuses.keys.sample,
    business_type: Invoice.business_types.keys.sample,
    discarded_at: nil
  )
    raise "Cannot create an invoice: No orders exist." if order.nil?

    company ||= order.company
    branch ||= order.branch

    calculated_total = order.order_appointments.sum(:total_price)
    total_price ||= (calculated_total > 0 ? calculated_total : Faker::Commerce.price(range: 50..2000.0))

    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil
    name ||= "Invoice for Order ##{order.id}"
    number ||= "INV-#{order.id}-#{SecureRandom.hex(4).upcase}"

    Invoice.new(
      order: order,
      company: company,
      branch: branch,
      name: name,
      description: description,
      currency_code: currency_code,
      number: number,
      total_price: total_price,
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
