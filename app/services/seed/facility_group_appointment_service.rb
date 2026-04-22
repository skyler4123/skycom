class Seed::FacilityGroupAppointmentService
  def self.create(
    company:,
    facility_group:,
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
    raise "Cannot create appointment: No company or facility_group provided." if company.nil? || facility_group.nil?

    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil
    name ||= "#{facility_group.name} Appointment"

    FacilityGroupAppointment.create!(
      company: company,
      facility_group: facility_group,
      appoint_from: appoint_from,
      appoint_to: appoint_to,
      appoint_for: appoint_for,
      appoint_by: appoint_by,
      name: name,
      description: description || "Facility group appointment for #{facility_group.name}.",
      code: code || "FGR-APT-#{SecureRandom.hex(4).upcase}",
      lifecycle_status: lifecycle_status || FacilityGroupAppointment.lifecycle_statuses.keys.sample,
      workflow_status: workflow_status || FacilityGroupAppointment.workflow_statuses.keys.sample,
      business_type: business_type || FacilityGroupAppointment.business_types.keys.sample,
      discarded_at: discarded_at
    )
  end
end
