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

  def self.new(
    name:,
    description: nil,
    code: nil,
    category: nil,
    property_mapping: nil,
    lifecycle_status: PaymentMethod.lifecycle_statuses.keys.sample,
    workflow_status: PaymentMethod.workflow_statuses.keys.sample,
    business_type: PaymentMethod.business_types.keys.sample,
    discarded_at: nil
  )
    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil

    PaymentMethod.new(
      name: name,
      description: description || "Payment method for #{name}.",
      code: code || "PM-#{SecureRandom.hex(4).upcase}",
      category: category,
      property_mapping: property_mapping,
      lifecycle_status: lifecycle_status,
      workflow_status: workflow_status,
      business_type: business_type,
      discarded_at: discarded_at
    )
  end

  def self.create(company: nil)
    puts "Seeding PaymentMethod records..."

    category = if company
      Seed::CategoryService.find_or_create_for(
        company: company,
        resource_name: PaymentMethod.model_name.plural
      )
    end

    # Use find_or_create_by to avoid duplicates on subsequent runs.
    PAYMENT_METHODS.each do |method_attrs|
      PaymentMethod.find_or_create_by!(code: method_attrs[:code]) do |pm|
        pm.name = method_attrs[:name]
        pm.description = "Payment method for #{method_attrs[:name]} transactions."
        pm.business_type = method_attrs[:business_type]
        pm.category = category if category
        pm.property_mapping = category.property_mapping if category
      end
    end

    puts "Successfully created #{PaymentMethod.count} PaymentMethod records."
  end
end
