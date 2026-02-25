# This service seeds the database with PaymentMethodAppointment records,
# linking global PaymentMethods to specific Branches. This allows branches
# to have their own configurations or subsets of available payment methods.

class Seed::PaymentMethodAppointmentService
  def self.create(
    company_group:,
    payment_method: PaymentMethod.all.sample,
    name: nil,
    description: nil,
    code: nil,
    lifecycle_status: PaymentMethodAppointment.lifecycle_statuses.keys.sample,
    workflow_status: PaymentMethodAppointment.workflow_statuses.keys.sample,
    business_type: PaymentMethodAppointment.business_types.keys.sample,
    discarded_at: nil
  )
    raise "Cannot create appointment: No company groups or payment methods exist." if company_group.nil? || payment_method.nil?

    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil
    name ||= "#{payment_method.name} for #{company_group.name}"
    description ||= "Company-specific configuration for #{payment_method.name}."
    code ||= "#{payment_method.code}_#{company_group.id}_#{SecureRandom.hex(4)}" # Ensure unique code

    PaymentMethodAppointment.create!(
      company_group: company_group,
      payment_method: payment_method,
      name: name,
      description: description,
      code: code,
      lifecycle_status: lifecycle_status,
      workflow_status: workflow_status,
      business_type: business_type,
      discarded_at: discarded_at
    )
  end
end
