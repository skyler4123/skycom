# This service seeds the database with payment method appointment records,
# linking global PaymentMethods to a Company (company-level) or a Branch
# (branch-level, requires an active company-level appointment).

class Seed::PaymentMethodAppointmentService
  def self.new(
    company:,
    payment_method: PaymentMethod.all.sample,
    branch: nil,
    appoint_to: nil,
    name: nil,
    description: nil,
    code: nil,
    merchant_number: nil,
    merchant_name: nil,
    merchant_id: nil,
    lifecycle_status: nil,
    workflow_status: nil,
    business_type: nil,
    discarded_at: nil
  )
    raise "Cannot create appointment: No company groups or payment methods exist." if company.nil? || payment_method.nil?

    branch ||= appoint_to if appoint_to.is_a?(Branch)
    lifecycle_status ||= branch ? :active : CompanyPaymentMethodAppointment.lifecycle_statuses.keys.sample
    workflow_status ||= (branch ? BranchPaymentMethodAppointment : CompanyPaymentMethodAppointment).workflow_statuses.keys.sample
    business_type ||= (branch ? BranchPaymentMethodAppointment : CompanyPaymentMethodAppointment).business_types.keys.sample

    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil
    name ||= "#{payment_method.name} for #{branch&.name || company.name}"
    description ||= "Company-specific configuration for #{payment_method.name}."
    code ||= "#{payment_method.code}_#{company.id}_#{SecureRandom.hex(4)}"

    if branch
      BranchPaymentMethodAppointment.new(
        company: company,
        branch: branch,
        payment_method: payment_method,
        name: name,
        description: description,
        code: code,
        merchant_number: merchant_number,
        merchant_name: merchant_name,
        merchant_id: merchant_id,
        lifecycle_status: lifecycle_status,
        workflow_status: workflow_status,
        business_type: business_type,
        discarded_at: discarded_at
      )
    else
      CompanyPaymentMethodAppointment.new(
        company: company,
        payment_method: payment_method,
        name: name,
        description: description,
        code: code,
        merchant_number: merchant_number,
        merchant_name: merchant_name,
        merchant_id: merchant_id,
        lifecycle_status: lifecycle_status,
        workflow_status: workflow_status,
        business_type: business_type,
        discarded_at: discarded_at
      )
    end
  end

  def self.create(...)
    appointment = new(...)
    appointment.save!
    appointment
  end
end
