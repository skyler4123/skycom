class Seed::BillingPaymentMethodService
  MOCK_API_BASE = "http://localhost:4000"

  def self.create
    puts "Seeding BillingPaymentMethod records..."

    BillingPaymentMethod.find_or_create_by!(code: "CASH") do |bpm|
      bpm.name = "Cash"
      bpm.description = "Cash payment"
      bpm.business_type = :b2b
      bpm.payment_mode = :cash
      bpm.strategy = :cash
      bpm.gateway_url = nil
      bpm.workflow_status = :confirmed
    end

    BillingPaymentMethod.find_or_create_by!(code: "WALLET_AUTO_DEBIT") do |bpm|
      bpm.name = "Wallet Auto-Debit"
      bpm.description = "Automatic deduction from company wallet"
      bpm.business_type = :b2b
      bpm.payment_mode = :cash
      bpm.strategy = :wallet_auto_debit
      bpm.gateway_url = nil
      bpm.workflow_status = :confirmed
    end

    BillingPaymentMethod.find_or_create_by!(code: "QR_BANK_TRANSFER") do |bpm|
      bpm.name = "QR Bank Transfer"
      bpm.description = "Pay via QR code and bank transfer"
      bpm.business_type = :b2b
      bpm.payment_mode = :qr
      bpm.strategy = :mock_qr_gateway
      bpm.gateway_url = "#{MOCK_API_BASE}/api/v1/bank/qr-generate"
      bpm.workflow_status = :confirmed
    end

    BillingPaymentMethod.find_or_create_by!(code: "REDIRECT_SESSION") do |bpm|
      bpm.name = "Redirect Payment"
      bpm.description = "Pay via hosted redirect session"
      bpm.business_type = :b2b
      bpm.payment_mode = :redirect
      bpm.strategy = :mock_redirect_gateway
      bpm.gateway_url = "#{MOCK_API_BASE}/api/v1/bank/redirect-session"
      bpm.workflow_status = :confirmed
    end

    BillingPaymentMethod.find_or_create_by!(code: "STRIPE_GATEWAY") do |bpm|
      bpm.name = "Stripe"
      bpm.description = "Pay via Stripe"
      bpm.business_type = :b2b
      bpm.payment_mode = :redirect
      bpm.strategy = :stripe_gateway
      bpm.gateway_url = nil
      bpm.workflow_status = :confirmed
    end

    BillingPaymentMethod.find_or_create_by!(code: "VIETQR_GATEWAY") do |bpm|
      bpm.name = "VietQR"
      bpm.description = "Pay via VietQR"
      bpm.business_type = :b2b
      bpm.payment_mode = :qr
      bpm.strategy = :viet_qr_gateway
      bpm.gateway_url = nil
      bpm.workflow_status = :confirmed
    end

    puts "Successfully created #{BillingPaymentMethod.count} BillingPaymentMethod records."
  end
end
