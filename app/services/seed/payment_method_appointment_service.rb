# This service seeds the database with PaymentMethodAppointment records,
# linking global PaymentMethods to specific Companies. This allows companies
# to have their own configurations or subsets of available payment methods.

class Seed::PaymentMethodAppointmentService
  def self.create(
    company_group:,
    payment_method: PaymentMethod.all.sample,
    name: nil,
    description: nil,
    code: nil,
    lifecycle_status: nil,
    workflow_status: nil,
    business_type: nil,
    discarded_at: nil
  )
    raise "Cannot create appointment: No company groups or payment methods exist." if company_group.nil? || payment_method.nil?

    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil

    PaymentMethodAppointment.create!(
      company_group: company_group,
      payment_method: payment_method,
      name: name || "#{payment_method.name} for #{company_group.name}",
      description: description || "Company-specific configuration for #{payment_method.name}.",
      code: code || "#{payment_method.code}_#{company_group.id}_#{SecureRandom.hex(4)}", # Ensure unique code
      lifecycle_status: lifecycle_status || PaymentMethodAppointment.lifecycle_statuses.keys.sample,
      workflow_status: workflow_status || PaymentMethodAppointment.workflow_statuses.keys.sample,
      business_type: business_type || PaymentMethodAppointment.business_types.keys.sample,
      discarded_at: discarded_at
    )
  end
end
