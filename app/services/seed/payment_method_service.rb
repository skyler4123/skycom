# This service seeds the database with a predefined list of global PaymentMethod
# records. These are not tied to any specific company and represent the
# available payment options across the application.

class Seed::PaymentMethodService
  COUNTRY_CODES = {
    us: 840,
    vn: 704
  }.freeze

  MOCK_API_BASE = "http://localhost:4000"
  MOCK_REDIRECT_URL = "#{MOCK_API_BASE}/api/v1/bank/redirect-session".freeze
  MOCK_QR_URL = "#{MOCK_API_BASE}/api/v1/bank/qr-generate".freeze

  PAYMENT_METHODS = {
    us: [
      { name: "Credit Card",       code: "CREDIT_CARD",   business_type: :b2c, country_code: COUNTRY_CODES[:us], payment_mode: :redirect, gateway_url: MOCK_REDIRECT_URL, secret_key: "sk_test_credit_card_#{SecureRandom.hex(8)}" },
      { name: "Debit Card",        code: "DEBIT_CARD",    business_type: :b2c, country_code: COUNTRY_CODES[:us], payment_mode: :redirect, gateway_url: MOCK_REDIRECT_URL, secret_key: "sk_test_debit_card_#{SecureRandom.hex(8)}" },
      { name: "PayPal",            code: "PAYPAL",        business_type: :b2c, country_code: COUNTRY_CODES[:us], payment_mode: :redirect, gateway_url: MOCK_REDIRECT_URL, secret_key: "sk_test_paypal_#{SecureRandom.hex(8)}" },
      { name: "Apple Pay",         code: "APPLE_PAY",     business_type: :b2c, country_code: COUNTRY_CODES[:us], payment_mode: :redirect, gateway_url: MOCK_REDIRECT_URL, secret_key: "sk_test_apple_pay_#{SecureRandom.hex(8)}" },
      { name: "Google Pay",        code: "GOOGLE_PAY",    business_type: :b2c, country_code: COUNTRY_CODES[:us], payment_mode: :redirect, gateway_url: MOCK_REDIRECT_URL, secret_key: "sk_test_google_pay_#{SecureRandom.hex(8)}" },
      { name: "Cash",              code: "CASH_US",        business_type: :b2c, country_code: COUNTRY_CODES[:us], payment_mode: :cash,     gateway_url: nil,                                  secret_key: nil },
      { name: "ACH Bank Transfer", code: "ACH_TRANSFER",  business_type: :b2b, country_code: COUNTRY_CODES[:us], payment_mode: :qr,       gateway_url: MOCK_QR_URL,                         secret_key: "sk_test_ach_#{SecureRandom.hex(8)}" },
      { name: "Wire Transfer",     code: "WIRE_TRANSFER", business_type: :b2b, country_code: COUNTRY_CODES[:us], payment_mode: :qr,       gateway_url: MOCK_QR_URL,                         secret_key: "sk_test_wire_#{SecureRandom.hex(8)}" },
      { name: "Stripe",            code: "STRIPE",        business_type: :b2b, country_code: COUNTRY_CODES[:us], payment_mode: :redirect, gateway_url: MOCK_REDIRECT_URL,                    secret_key: "sk_test_stripe_#{SecureRandom.hex(8)}" }
    ].freeze,
    vn: [
      { name: "MoMo",             code: "MOMO",           business_type: :b2c, country_code: COUNTRY_CODES[:vn], payment_mode: :redirect, gateway_url: MOCK_REDIRECT_URL, secret_key: "sk_test_momo_#{SecureRandom.hex(8)}" },
      { name: "ZaloPay",          code: "ZALOPAY",        business_type: :b2c, country_code: COUNTRY_CODES[:vn], payment_mode: :redirect, gateway_url: MOCK_REDIRECT_URL, secret_key: "sk_test_zalopay_#{SecureRandom.hex(8)}" },
      { name: "VNPay",            code: "VNPAY",          business_type: :b2c, country_code: COUNTRY_CODES[:vn], payment_mode: :redirect, gateway_url: MOCK_REDIRECT_URL, secret_key: "sk_test_vnpay_#{SecureRandom.hex(8)}" },
      { name: "Cash (VN)",        code: "CASH_VN",        business_type: :b2c, country_code: COUNTRY_CODES[:vn], payment_mode: :cash,     gateway_url: nil,                                  secret_key: nil },
      { name: "Credit Card (VN)", code: "CREDIT_CARD_VN", business_type: :b2c, country_code: COUNTRY_CODES[:vn], payment_mode: :redirect, gateway_url: MOCK_REDIRECT_URL,                    secret_key: "sk_test_credit_card_vn_#{SecureRandom.hex(8)}" },
      { name: "ShopeePay",        code: "SHOPEEPAY",      business_type: :b2c, country_code: COUNTRY_CODES[:vn], payment_mode: :redirect, gateway_url: MOCK_REDIRECT_URL,                    secret_key: "sk_test_shopeepay_#{SecureRandom.hex(8)}" },
      { name: "VietQR Transfer",  code: "VIETQR",         business_type: :b2b, country_code: COUNTRY_CODES[:vn], payment_mode: :qr,       gateway_url: MOCK_QR_URL,                         secret_key: "sk_test_vietqr_#{SecureRandom.hex(8)}" },
      { name: "Direct Debit",     code: "DIRECT_DEBIT",   business_type: :b2b, country_code: COUNTRY_CODES[:vn], payment_mode: :qr,       gateway_url: MOCK_QR_URL,                         secret_key: "sk_test_direct_debit_#{SecureRandom.hex(8)}" }
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
    payment_mode: nil,
    gateway_url: nil,
    secret_key: nil,
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
      payment_mode: payment_mode,
      gateway_url: gateway_url,
      secret_key: secret_key,
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
          pm.payment_mode = method_attrs[:payment_mode]
          pm.gateway_url = method_attrs[:gateway_url]
          pm.secret_key = method_attrs[:secret_key]
          pm.workflow_status = :active
        end
      end
    end

    puts "Successfully created #{PaymentMethod.count} PaymentMethod records."
  end
end
