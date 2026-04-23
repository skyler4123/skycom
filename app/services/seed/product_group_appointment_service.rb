class Seed::ProductGroupAppointmentService
  def self.new(
    company:,
    product_group:,
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
    raise "Cannot create appointment: No company or product_group provided." if company.nil? || product_group.nil?

    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil
    name ||= "#{product_group.name} Appointment"

    ProductGroupAppointment.new(
      company: company,
      product_group: product_group,
      appoint_from: appoint_from,
      appoint_to: appoint_to,
      appoint_for: appoint_for,
      appoint_by: appoint_by,
      name: name,
      description: description || "Product group appointment for #{product_group.name}.",
      code: code || "PGR-APT-#{SecureRandom.hex(4).upcase}",
      lifecycle_status: lifecycle_status || ProductGroupAppointment.lifecycle_statuses.keys.sample,
      workflow_status: workflow_status || ProductGroupAppointment.workflow_statuses.keys.sample,
      business_type: business_type || ProductGroupAppointment.business_types.keys.sample,
      discarded_at: discarded_at
    )
  end

  def self.create(...)
    appointment = new(...)
    appointment.save!
    appointment
  end
end
