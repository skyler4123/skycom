# This service seeds the database with Payment records. Each payment is
# associated with an existing Invoice. It uses enums from the Payment model
# and simulates soft deletion for a portion of the records.

class Seed::PaymentService
  # Configuration for the number of payments to create per invoice
  PAYMENTS_PER_INVOICE = 1

  def self.run
    # Get enum keys once before the loop for efficiency.
    statuses = Payment.statuses.keys
    business_types = Payment.business_types.keys
    payment_methods = Payment.payment_methods.keys

    puts "Seeding Payment records..."

    Invoice.all.each do |invoice|
      # Skip creating payments for draft or cancelled invoices
      next if %w[draft cancelled].include?(invoice.status)

      PAYMENTS_PER_INVOICE.times do
        # Randomly decide whether to mark the record as discarded
        should_discard = rand(10) == 0 # 10% chance of being discarded

        Payment.create!(
          invoice: invoice,
          name: "Payment for Invoice ##{invoice.number}",
          description: "Payment received for invoice #{invoice.number}.",
          currency: invoice.currency, # Use the invoice's currency
          exchange_rate: 1.0,
          amount: invoice.total, # Assume full payment for simplicity
          payment_method: payment_methods.sample,
          gateway_details: { transaction_id: SecureRandom.uuid, timestamp: Time.zone.now }.to_json,
          status: statuses.sample,
          business_type: business_types.sample,
          # Set a past timestamp for discarded_at if the record is to be soft-deleted
          discarded_at: should_discard ? Time.zone.now - rand(1..180).days : nil
        )
      end
    end

    puts "Successfully created #{Payment.count} Payment records."
  end

  def self.create(
    invoice: Invoice.where.not(status: %w[draft cancelled]).sample,
    name: nil,
    description: nil,
    currency: nil,
    exchange_rate: 1.0,
    amount: nil,
    payment_method: nil,
    gateway_details: { transaction_id: SecureRandom.uuid, timestamp: Time.zone.now }.to_json,
    status: nil,
    business_type: nil,
    discarded_at: nil
  )
    raise "Cannot create a payment: No suitable invoices exist." if invoice.nil?

    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil

    Payment.create!(
      invoice: invoice,
      name: name || "Payment for Invoice ##{invoice.number}",
      description: description || "Payment received for invoice #{invoice.number}.",
      currency: currency || invoice.currency,
      exchange_rate: exchange_rate,
      amount: amount || invoice.total,
      payment_method: payment_method || Payment.payment_methods.keys.sample,
      gateway_details: gateway_details,
      status: status || Payment.statuses.keys.sample,
      business_type: business_type || Payment.business_types.keys.sample,
      discarded_at: discarded_at
    )
  end
end
