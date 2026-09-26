class Seed::EmployeeProductAppointmentService
  def self.new(
    company:,
    employee:,
    product:,
    name: nil,
    description: nil,
    code: nil,
    discarded_at: nil
  )
    raise "Cannot create appointment: No company, employee or product provided." if company.nil? || employee.nil? || product.nil?

    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil
    name ||= "#{employee.name} Appointment"

    EmployeeProductAppointment.new(
      company: company,
      employee: employee,
      product: product,
      name: name,
      description: description || "Employee appointment for #{employee.name}.",
      code: code || "EMP-PROD-#{SecureRandom.hex(4).upcase}",
      discarded_at: discarded_at
    )
  end

  def self.create(...)
    appointment = new(...)
    appointment.save!
    appointment
  end
end
