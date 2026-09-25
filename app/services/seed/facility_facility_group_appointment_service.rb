class Seed::FacilityFacilityGroupAppointmentService
  def self.new(
    company:,
    facility:,
    facility_group:,
    name: nil,
    description: nil,
    code: nil,
    discarded_at: nil
  )
    raise "Cannot create appointment: No company, facility or facility_group provided." if company.nil? || facility.nil? || facility_group.nil?

    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil
    name ||= "#{facility.name} Appointment"

    FacilityFacilityGroupAppointment.new(
      company: company,
      facility: facility,
      facility_group: facility_group,
      name: name,
      description: description || "Facility appointment for #{facility.name}.",
      code: code || "FFG-#{SecureRandom.hex(4).upcase}",
      discarded_at: discarded_at
    )
  end

  def self.create(...)
    appointment = new(...)
    appointment.save!
    appointment
  end
end
