class Seed::CustomerAppointmentService
  def self.new(
    company:,
    customer:,
    appoint_from: nil,
    appoint_to:,
    appoint_for: nil,
    appoint_by: nil,
    name: nil,
    description: nil,
    code: nil,
    lifecycle_status: nil,
    workflow_status: nil,
    business_type: nil,
    discarded_at: nil
  )
    raise "Cannot create appointment: No company or customer provided." if company.nil? || customer.nil?

    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil
    name ||= "#{customer.name} Appointment"

    CustomerAppointment.new(
      company: company,
      customer: customer,
      appoint_from: appoint_from,
      appoint_to: appoint_to,
      appoint_for: appoint_for,
      appoint_by: appoint_by,
      name: name,
      description: description || "Customer appointment for #{customer.name}.",
      code: code || "CUST-APT-#{SecureRandom.hex(4).upcase}",
      lifecycle_status: lifecycle_status || CustomerAppointment.lifecycle_statuses.keys.sample,
      workflow_status: workflow_status || CustomerAppointment.workflow_statuses.keys.sample,
      business_type: business_type || CustomerAppointment.business_types.keys.sample,
      discarded_at: discarded_at
    )
  end

  def self.create(...)
    appointment = new(...)
    appointment.save!
    appointment
  end
end
