class Seed::DocumentGroupEmployeeAppointmentService
  def self.new(
    company:,
    document_group:,
    employee:,
    name: nil,
    description: nil,
    code: nil,
    discarded_at: nil
  )
    raise "Cannot create appointment: No company, document_group or employee provided." if company.nil? || document_group.nil? || employee.nil?

    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil
    name ||= "#{document_group.name} Appointment"

    DocumentGroupEmployeeAppointment.new(
      company: company,
      document_group: document_group,
      employee: employee,
      name: name,
      description: description || "Document group appointment for #{document_group.name}.",
      code: code || "DGE-#{SecureRandom.hex(4).upcase}",
      discarded_at: discarded_at
    )
  end

  def self.create(...)
    appointment = new(...)
    appointment.save!
    appointment
  end
end
