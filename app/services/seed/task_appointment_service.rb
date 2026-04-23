class Seed::TaskAppointmentService
  def self.new(
    company:,
    task:,
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
    raise "Cannot create appointment: No company or task provided." if company.nil? || task.nil?

    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil
    name ||= "#{task.name} Appointment"

    TaskAppointment.new(
      company: company,
      task: task,
      appoint_from: appoint_from,
      appoint_to: appoint_to,
      appoint_for: appoint_for,
      appoint_by: appoint_by,
      name: name,
      description: description || "Task appointment for #{task.name}.",
      code: code || "TSK-APT-#{SecureRandom.hex(4).upcase}",
      lifecycle_status: lifecycle_status || TaskAppointment.lifecycle_statuses.keys.sample,
      workflow_status: workflow_status || TaskAppointment.workflow_statuses.keys.sample,
      business_type: business_type || TaskAppointment.business_types.keys.sample,
      discarded_at: discarded_at
    )
  end

  def self.create(...)
    appointment = new(...)
    appointment.save!
    appointment
  end
end
