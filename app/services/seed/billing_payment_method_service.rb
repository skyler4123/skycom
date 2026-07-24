class Seed::BillingPaymentMethodService
  RECORDS = [
    { code: "CASH",             name: "Cash",              business_type: :b2b, payment_mode: :cash,    strategy: :cash,              lifecycle_status: nil },
    { code: "WALLET_AUTO_DEBIT", name: "Wallet Auto-Debit", business_type: :b2b, payment_mode: :cash,    strategy: :wallet_auto_debit, lifecycle_status: nil },
    { code: "STRIPE_GATEWAY",    name: "Stripe",            business_type: :b2b, payment_mode: :redirect, strategy: :stripe_gateway,    lifecycle_status: nil },
    { code: "VIETQR_GATEWAY",    name: "VietQR",            business_type: :b2b, payment_mode: :qr,      strategy: :viet_qr_gateway,   lifecycle_status: nil }
  ].freeze

  MOCK_RECORDS = [
    { code: "QR_BANK_TRANSFER",  name: "Mock QR",           business_type: :b2b, payment_mode: :qr,      strategy: :mock_qr_gateway,       lifecycle_status: :active },
    { code: "REDIRECT_SESSION",  name: "Mock Redirect",     business_type: :b2b, payment_mode: :redirect, strategy: :mock_redirect_gateway, lifecycle_status: :active }
  ].freeze

  ALL_RECORDS = (RECORDS + (Rails.env.production? ? [] : MOCK_RECORDS)).freeze

  def self.create
    puts "Seeding BillingPaymentMethod records..."

    ALL_RECORDS.each do |attrs|
      BillingPaymentMethod.find_or_create_by!(code: attrs[:code]) do |bpm|
        bpm.name = attrs[:name]
        bpm.business_type = attrs[:business_type]
        bpm.payment_mode = attrs[:payment_mode]
        bpm.strategy = attrs[:strategy]
        bpm.workflow_status = :confirmed
        bpm.lifecycle_status = attrs[:lifecycle_status] || :draft
      end
    end

    puts "Successfully created #{BillingPaymentMethod.count} BillingPaymentMethod records."
  end
end
