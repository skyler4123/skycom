class Seed::PeriodAppointmentService
  def self.new(
    period:,
    appoint_from: nil,
    appoint_to:,
    appoint_for: nil,
    appoint_by: nil,
    name: nil,
    description: nil,
    code: nil,
    value: nil,
    lifecycle_status: nil,
    workflow_status: nil,
    business_type: nil,
    discarded_at: nil
  )
    raise "Cannot create appointment: No period provided." if period.nil?

    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil
    name ||= "#{period.formatted_offset} Appointment"

    PeriodAppointment.new(
      period: period,
      appoint_from: appoint_from,
      appoint_to: appoint_to,
      appoint_for: appoint_for,
      appoint_by: appoint_by,
      name: name,
      description: description || "Period appointment for #{period.formatted_offset}.",
      code: code || "PRD-APT-#{SecureRandom.hex(4).upcase}",
      value: value || period.formatted_offset,
      lifecycle_status: lifecycle_status || PeriodAppointment.lifecycle_statuses.keys.sample,
      workflow_status: workflow_status || PeriodAppointment.workflow_statuses.keys.sample,
      business_type: business_type || PeriodAppointment.business_types.keys.sample,
      discarded_at: discarded_at
    )
  end

  def self.create(...)
    appointment = new(...)
    appointment.save!
    appointment
  end
end
