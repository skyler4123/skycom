# Seeds the global PaymentMethod catalog — one record per gateway strategy.
# Cash is a system payment (no gateway). Other strategies resolve to a
# gateway implementation class via GATEWAY_STRATEGY_CLASSES.

class Seed::PaymentMethodService
  MOCK_API_BASE = "http://localhost:4000"

  # NOTE: secret_key is intentionally nil here. It's a real credential that must
  # be set per-deployment via the admin UI or environment configuration — never
  # hardcoded in seed data.
  PAYMENT_METHODS = [
    { name: "Cash",              code: "CASH",          business_type: :b2c, strategy: :cash,              payment_mode: :cash,     gateway_url: nil },
    { name: "QR Payment",        code: "MOCK_QR",       business_type: :b2c, strategy: :mock_qr_gateway,   payment_mode: :qr,       gateway_url: "#{MOCK_API_BASE}/api/v1/bank/qr-generate" },
    { name: "Online Payment",    code: "MOCK_REDIRECT", business_type: :b2c, strategy: :mock_redirect_gateway, payment_mode: :redirect, gateway_url: "#{MOCK_API_BASE}/api/v1/bank/redirect-session" },
    { name: "Credit Card",       code: "STRIPE",        business_type: :b2c, strategy: :stripe_gateway,    payment_mode: :redirect, gateway_url: nil },
    { name: "VietQR Transfer",   code: "VIETQR",        business_type: :b2c, strategy: :viet_qr_gateway,   payment_mode: :qr,       gateway_url: nil }
  ].freeze

  def self.new(
    name:,
    description: nil,
    code: nil,
    strategy: nil,
    lifecycle_status: PaymentMethod.lifecycle_statuses.keys.sample,
    workflow_status: PaymentMethod.workflow_statuses.keys.sample,
    business_type: PaymentMethod.business_types.keys.sample,
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
      strategy: strategy,
      lifecycle_status: lifecycle_status,
      workflow_status: workflow_status,
      business_type: business_type,
      payment_mode: payment_mode,
      gateway_url: gateway_url,
      secret_key: secret_key,
      discarded_at: discarded_at
    )
  end

  def self.create(company: nil)
    puts "Seeding PaymentMethod records..."

    PAYMENT_METHODS.each do |attrs|
      PaymentMethod.find_or_create_by!(code: attrs[:code]) do |pm|
        pm.name = attrs[:name]
        pm.description = "Payment method for #{attrs[:name]} transactions."
        pm.business_type = attrs[:business_type]
        pm.strategy = attrs[:strategy]
        pm.payment_mode = attrs[:payment_mode]
        pm.gateway_url = attrs[:gateway_url]
        pm.workflow_status = :confirmed
      end
    end

    puts "Successfully created #{PaymentMethod.count} PaymentMethod records."
  end
end
