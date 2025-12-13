# This service seeds the database with a predefined list of global PaymentMethod
# records. These are not tied to any specific company and represent the
# available payment options across the application.

class Seed::PaymentMethodService
  # A predefined list of common payment methods to create.
  PAYMENT_METHODS = [
    { name: "Credit Card", code: "CREDIT_CARD", business_type: :global, status: :active },
    { name: "PayPal", code: "PAYPAL", business_type: :online, status: :active },
    { name: "Bank Transfer", code: "BANK_TRANSFER", business_type: :global, status: :active },
    { name: "Cash", code: "CASH", business_type: :offline, status: :active },
    { name: "Apple Pay", code: "APPLE_PAY", business_type: :online, status: :active },
    { name: "Google Pay", code: "GOOGLE_PAY", business_type: :online, status: :active },
    { name: "Stripe", code: "STRIPE", business_type: :online, status: :restricted }
  ].freeze

  def self.create
    puts "Seeding PaymentMethod records..."

    # Use find_or_create_by to avoid duplicates on subsequent runs.
    PAYMENT_METHODS.each do |method_attrs|
      PaymentMethod.find_or_create_by!(code: method_attrs[:code]) do |pm|
        pm.name = method_attrs[:name]
        pm.description = "Payment method for #{method_attrs[:name]} transactions."
        pm.business_type = method_attrs[:business_type]
        pm.status = method_attrs[:status]
        # Currency can be left nil for global methods or set to a default
        # pm.currency = :usd
      end
    end

    puts "Successfully created #{PaymentMethod.count} PaymentMethod records."
  end
end
