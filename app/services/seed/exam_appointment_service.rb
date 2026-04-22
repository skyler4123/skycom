class Seed::ExamAppointmentService
  def self.create(
    company:,
    exam:,
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
    raise "Cannot create appointment: No company or exam provided." if company.nil? || exam.nil?

    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil
    name ||= "#{exam.name} Appointment"

    ExamAppointment.create!(
      company: company,
      exam: exam,
      appoint_from: appoint_from,
      appoint_to: appoint_to,
      appoint_for: appoint_for,
      appoint_by: appoint_by,
      name: name,
      description: description || "Exam appointment for #{exam.name}.",
      code: code || "EXAM-APT-#{SecureRandom.hex(4).upcase}",
      lifecycle_status: lifecycle_status || ExamAppointment.lifecycle_statuses.keys.sample,
      workflow_status: workflow_status || ExamAppointment.workflow_statuses.keys.sample,
      business_type: business_type || ExamAppointment.business_types.keys.sample,
      discarded_at: discarded_at
    )
  end
end
