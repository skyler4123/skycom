# This service seeds the database with a predefined list of global PaymentMethod
# records. These are not tied to any specific company and represent the
# available payment options across the application.

class Seed::PaymentMethodService
  COUNTRY_CODES = {
    us: 840,
    vn: 704
  }.freeze

  PAYMENT_METHODS = {
    us: [
      { name: "Credit Card",       code: "CREDIT_CARD",   business_type: :b2c, country_code: COUNTRY_CODES[:us] },
      { name: "Debit Card",        code: "DEBIT_CARD",    business_type: :b2c, country_code: COUNTRY_CODES[:us] },
      { name: "PayPal",            code: "PAYPAL",        business_type: :b2c, country_code: COUNTRY_CODES[:us] },
      { name: "Apple Pay",         code: "APPLE_PAY",     business_type: :b2c, country_code: COUNTRY_CODES[:us] },
      { name: "Google Pay",        code: "GOOGLE_PAY",    business_type: :b2c, country_code: COUNTRY_CODES[:us] },
      { name: "Cash",              code: "CASH_US",        business_type: :b2c, country_code: COUNTRY_CODES[:us] },
      { name: "ACH Bank Transfer", code: "ACH_TRANSFER",  business_type: :b2b, country_code: COUNTRY_CODES[:us] },
      { name: "Wire Transfer",     code: "WIRE_TRANSFER", business_type: :b2b, country_code: COUNTRY_CODES[:us] },
      { name: "Stripe",            code: "STRIPE",        business_type: :b2b, country_code: COUNTRY_CODES[:us] }
    ].freeze,
    vn: [
      { name: "MoMo",             code: "MOMO",           business_type: :b2c, country_code: COUNTRY_CODES[:vn] },
      { name: "ZaloPay",          code: "ZALOPAY",        business_type: :b2c, country_code: COUNTRY_CODES[:vn] },
      { name: "VNPay",            code: "VNPAY",          business_type: :b2c, country_code: COUNTRY_CODES[:vn] },
      { name: "Cash (VN)",        code: "CASH_VN",        business_type: :b2c, country_code: COUNTRY_CODES[:vn] },
      { name: "Credit Card (VN)", code: "CREDIT_CARD_VN", business_type: :b2c, country_code: COUNTRY_CODES[:vn] },
      { name: "ShopeePay",        code: "SHOPEEPAY",      business_type: :b2c, country_code: COUNTRY_CODES[:vn] },
      { name: "VietQR Transfer",  code: "VIETQR",         business_type: :b2b, country_code: COUNTRY_CODES[:vn] },
      { name: "Direct Debit",     code: "DIRECT_DEBIT",   business_type: :b2b, country_code: COUNTRY_CODES[:vn] }
    ].freeze
  }.freeze

  def self.new(
    name:,
    description: nil,
    code: nil,
    lifecycle_status: PaymentMethod.lifecycle_statuses.keys.sample,
    workflow_status: PaymentMethod.workflow_statuses.keys.sample,
    business_type: PaymentMethod.business_types.keys.sample,
    country_code: 840,
    discarded_at: nil
  )
    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil

    PaymentMethod.new(
      name: name,
      description: description || "Payment method for #{name}.",
      code: code || "PM-#{SecureRandom.hex(4).upcase}",
      lifecycle_status: lifecycle_status,
      workflow_status: workflow_status,
      business_type: business_type,
      country_code: country_code,
      discarded_at: discarded_at
    )
  end

  def self.create(company: nil)
    puts "Seeding PaymentMethod records..."

    PAYMENT_METHODS.each do |country_key, methods|
      methods.each do |method_attrs|
        PaymentMethod.find_or_create_by!(code: method_attrs[:code]) do |pm|
          pm.name = method_attrs[:name]
          pm.description = "Payment method for #{method_attrs[:name]} transactions."
          pm.business_type = method_attrs[:business_type]
          pm.country_code = method_attrs[:country_code]
          pm.workflow_status = :active
        end
      end
    end

    puts "Successfully created #{PaymentMethod.count} PaymentMethod records."
  end
end
