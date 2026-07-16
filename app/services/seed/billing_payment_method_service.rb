class Seed::BillingPaymentMethodService
  def self.create
    puts "Seeding BillingPaymentMethod records..."

    BillingPaymentMethod.find_or_create_by!(code: "WALLET_AUTO_DEBIT") do |bpm|
      bpm.name = "Wallet Auto-Debit"
      bpm.description = "Automatic deduction from company wallet"
      bpm.business_type = :b2b
      bpm.payment_mode = :cash
      bpm.gateway_url = nil
      bpm.workflow_status = :confirmed
    end

    BillingPaymentMethod.find_or_create_by!(code: "QR_BANK_TRANSFER") do |bpm|
      bpm.name = "QR Bank Transfer"
      bpm.description = "Pay via QR code and bank transfer"
      bpm.business_type = :b2b
      bpm.payment_mode = :qr
      bpm.gateway_url = "http://localhost:4000/api/v1/bank/qr-generate"
      bpm.workflow_status = :confirmed
    end

    puts "Successfully created #{BillingPaymentMethod.count} BillingPaymentMethod records."
  end
end
