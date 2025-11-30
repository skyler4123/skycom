# This service seeds the database with Invoice records. Each invoice is
# associated with an existing Order. It uses enums from the Invoice model
# and simulates soft deletion for a portion of the records.

class Seed::InvoiceService

  # Configuration for the number of invoices to create per order
  INVOICES_PER_ORDER = 1

  def self.run
    # Get enum keys once before the loop for efficiency.
    statuses = Invoice.statuses.keys
    business_types = Invoice.business_types.keys

    puts "Seeding Invoice records..."

    Order.all.each do |order|
      INVOICES_PER_ORDER.times do |i|
        # Randomly decide whether to mark the record as discarded
        should_discard = rand(10) == 0 # 10% chance of being discarded

        # Calculate total from order items if available, otherwise use a random price
        calculated_total = order.order_appointments.sum(:total_price)
        invoice_total = calculated_total > 0 ? calculated_total : Faker::Commerce.price(range: 50..2000.0)

        Invoice.create!(
          order: order,
          name: "Invoice for Order ##{order.id}",
          description: Faker::Lorem.sentence(word_count: 10),
          currency: Invoice.currencies.keys.sample, # Use the order's currency
          number: "INV-#{order.id}-#{i + 1}-#{SecureRandom.hex(4).upcase}", # Unique invoice number
          total: invoice_total,
          due_date: Faker::Date.forward(days: 30),
          status: statuses.sample,
          business_type: business_types.sample,
          # Set a past timestamp for discarded_at if the record is to be soft-deleted
          discarded_at: should_discard ? Time.zone.now - rand(1..180).days : nil
        )
      end
    end

    puts "Successfully created #{Invoice.count} Invoice records."
  end

  def self.create(
    order:,
    name: nil,
    description: Faker::Lorem.sentence(word_count: 10),
    currency: nil,
    number: nil,
    total: nil,
    due_date: Faker::Date.forward(days: 30),
    status: nil,
    business_type: nil,
    discarded_at: nil
  )
    raise "Cannot create an invoice: No orders exist." if order.nil?

    calculated_total = order.order_appointments.sum(:total_price)
    invoice_total = total || (calculated_total > 0 ? calculated_total : Faker::Commerce.price(range: 50..2000.0))

    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil

    Invoice.create!(
      order: order,
      name: name || "Invoice for Order ##{order.id}",
      description: description,
      currency: currency || Invoice.currencies.keys.sample,
      number: number || "INV-#{order.id}-#{SecureRandom.hex(4).upcase}",
      total: invoice_total,
      due_date: due_date,
      status: status || Invoice.statuses.keys.sample,
      business_type: business_type || Invoice.business_types.keys.sample,
      discarded_at: discarded_at
    )
  end
end