# This service seeds the database with PaymentMethodAppointment records,
# linking global PaymentMethods to specific Companies. This allows companies
# to have their own configurations or subsets of available payment methods.

class Seed::PaymentMethodAppointmentService
  # Configuration for the number of payment methods to appoint per company
  PAYMENT_METHODS_PER_COMPANY = 3

  def self.run
    puts "Seeding PaymentMethodAppointment records..."

    # Get all available global payment methods
    all_payment_methods = PaymentMethod.all
    return if all_payment_methods.empty?

    # Get enum keys for PaymentMethodAppointment
    statuses = PaymentMethodAppointment.statuses.keys
    business_types = PaymentMethodAppointment.business_types.keys

    Company.all.each do |company|
      # Randomly select a subset of global payment methods for this company
      appointed_methods = all_payment_methods.sample(PAYMENT_METHODS_PER_COMPANY)

      appointed_methods.each do |payment_method|
        # Randomly decide whether to mark the record as discarded
        should_discard = rand(10) == 0 # 10% chance of being discarded

        PaymentMethodAppointment.create!(
          company: company,
          payment_method: payment_method,
          name: "#{payment_method.name} for #{company.name}",
          description: "Company-specific configuration for #{payment_method.name}.",
          code: "#{payment_method.code}_#{company.id}", # Ensure unique code per company
          status: statuses.sample,
          business_type: business_types.sample,
          # Set a past timestamp for discarded_at if the record is to be soft-deleted
          discarded_at: should_discard ? Time.zone.now - rand(1..180).days : nil
        )
      end
    end

    puts "Successfully created #{PaymentMethodAppointment.count} PaymentMethodAppointment records."
  end

  def self.create(
    company:,
    payment_method: PaymentMethod.all.sample,
    name: nil,
    description: nil,
    code: nil,
    status: nil,
    business_type: nil,
    discarded_at: nil
  )
    raise "Cannot create appointment: No companies or payment methods exist." if company.nil? || payment_method.nil?

    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil

    PaymentMethodAppointment.create!(
      company: company,
      payment_method: payment_method,
      name: name || "#{payment_method.name} for #{company.name}",
      description: description || "Company-specific configuration for #{payment_method.name}.",
      code: code || "#{payment_method.code}_#{company.id}_#{SecureRandom.hex(4)}", # Ensure unique code
      status: status || PaymentMethodAppointment.statuses.keys.sample,
      business_type: business_type || PaymentMethodAppointment.business_types.keys.sample,
      discarded_at: discarded_at
    )
  end
end