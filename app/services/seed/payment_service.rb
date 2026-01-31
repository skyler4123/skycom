# This service seeds the database with Payment records. Each payment is
# associated with an existing Invoice. It uses enums from the Payment model
# and simulates soft deletion for a portion of the records.

class Seed::PaymentService
  def self.create(
    invoice: Invoice.where.not(status: %w[draft cancelled]).sample,
    name: nil,
    description: nil,
    currency_code: nil,
    exchange_rate: 1.0,
    amount: nil,
    payment_method: Payment.payment_methods.keys.sample,
    gateway_details: { transaction_id: SecureRandom.uuid, timestamp: Time.zone.now }.to_json,
    status: Payment.statuses.keys.sample,
    business_type: Payment.business_types.keys.sample,
    discarded_at: nil
  )
    raise "Cannot create a payment: No suitable invoices exist." if invoice.nil?

    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil
    name ||= "Payment for Invoice ##{invoice.number}"
    description ||= "Payment received for invoice #{invoice.number}."
    currency ||= invoice.currency
    amount ||= invoice.total

    Payment.create!(
      invoice: invoice,
      name: name,
      description: description,
      currency_code: currency_code,
      exchange_rate: exchange_rate,
      amount: amount,
      payment_method: payment_method,
      gateway_details: gateway_details,
      status: status,
      business_type: business_type,
      discarded_at: discarded_at
    )
  end
end
