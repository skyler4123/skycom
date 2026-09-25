class Seed::DocumentEmployeeAppointmentService
  def self.new(
    company:,
    document:,
    employee:,
    name: nil,
    description: nil,
    code: nil,
    discarded_at: nil
  )
    raise "Cannot create appointment: No company, document or employee provided." if company.nil? || document.nil? || employee.nil?

    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil
    name ||= "#{document.name} Appointment"

    DocumentEmployeeAppointment.new(
      company: company,
      document: document,
      employee: employee,
      name: name,
      description: description || "Document appointment for #{document.name}.",
      code: code || "DOC-EMP-#{SecureRandom.hex(4).upcase}",
      discarded_at: discarded_at
    )
  end

  def self.create(...)
    appointment = new(...)
    appointment.save!
    appointment
  end
end
