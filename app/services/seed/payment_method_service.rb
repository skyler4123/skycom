# Seeds the global PaymentMethod catalog — one record per gateway strategy.
# Cash is a system payment (no gateway). Other strategies resolve to a
# gateway implementation class via GATEWAY_STRATEGY_CLASSES.

class Seed::PaymentMethodService
  PAYMENT_METHODS = [
    { name: "Cash",              code: "CASH",          business_type: :b2c, strategy: :cash,              payment_mode: :cash,    lifecycle_status: :active },
    { name: "Mock QR",           code: "MOCK_QR",       business_type: :b2c, strategy: :mock_qr_gateway,   payment_mode: :qr,      lifecycle_status: :active },
    { name: "Mock Redirect",     code: "MOCK_REDIRECT", business_type: :b2c, strategy: :mock_redirect_gateway, payment_mode: :redirect, lifecycle_status: :active },
    { name: "Credit Card",       code: "STRIPE",        business_type: :b2c, strategy: :stripe_gateway,    payment_mode: :redirect },
    { name: "VietQR Transfer",   code: "VIETQR",        business_type: :b2c, strategy: :viet_qr_gateway,   payment_mode: :qr }
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
    country: nil,
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
      country: country,
      discarded_at: discarded_at
    )
  end

  def self.create(company: nil)
    puts "Seeding PaymentMethod records..."

    COUNTRY_CODES.keys.each do |country_code|
      PAYMENT_METHODS.each do |attrs|
        suffix = country_code.to_s.upcase
        code = "#{attrs[:code]}_#{suffix}"
        PaymentMethod.find_or_create_by!(code: code) do |pm|
          pm.name = "#{attrs[:name]} (#{suffix})"
          pm.description = "Payment method for #{attrs[:name]} transactions."
          pm.business_type = attrs[:business_type]
          pm.strategy = attrs[:strategy]
          pm.payment_mode = attrs[:payment_mode]
          pm.country = country_code
          pm.workflow_status = :confirmed
          pm.lifecycle_status = attrs[:lifecycle_status] || :draft
        end
      end
    end

    puts "Successfully created #{PaymentMethod.count} PaymentMethod records."
  end
end
