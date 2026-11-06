class Seed::EmployeeExamAppointmentService
  def self.new(
    company:,
    employee:,
    exam:,
    name: nil,
    description: nil,
    code: nil,
    discarded_at: nil
  )
    raise "Cannot create appointment: No company, employee or exam provided." if company.nil? || employee.nil? || exam.nil?

    name ||= "#{employee.name} exam attempt"
    EmployeeExamAppointment.new(
      company: company,
      employee: employee,
      exam: exam,
      name: name,
      description: description || "Exam attempt for #{exam.name}.",
      code: code || "EMP-EXM-#{SecureRandom.hex(4).upcase}",
      workflow_status: :assigned,
      attempt_number: 1,
      discarded_at: discarded_at
    )
  end

  def self.create(...)
    appointment = new(...)
    appointment.save!
    appointment
  end
end
