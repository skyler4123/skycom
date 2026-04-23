class Seed::FacilityAppointmentService
  def self.new(
    company:,
    facility:,
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
    raise "Cannot create appointment: No company or facility provided." if company.nil? || facility.nil?

    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil
    name ||= "#{facility.name} Appointment"

    FacilityAppointment.new(
      company: company,
      facility: facility,
      appoint_from: appoint_from,
      appoint_to: appoint_to,
      appoint_for: appoint_for,
      appoint_by: appoint_by,
      name: name,
      description: description || "Facility appointment for #{facility.name}.",
      code: code || "FAC-APT-#{SecureRandom.hex(4).upcase}",
      lifecycle_status: lifecycle_status || FacilityAppointment.lifecycle_statuses.keys.sample,
      workflow_status: workflow_status || FacilityAppointment.workflow_statuses.keys.sample,
      business_type: business_type || FacilityAppointment.business_types.keys.sample,
      discarded_at: discarded_at
    )
  end

  def self.create(...)
    appointment = new(...)
    appointment.save!
    appointment
  end
end
