class Seed::CustomerEmployeeAppointmentService
  def self.new(
    company:,
    customer:,
    employee:,
    name: nil,
    description: nil,
    code: nil,
    discarded_at: nil
  )
    raise "Cannot create appointment: No company, customer or employee provided." if company.nil? || customer.nil? || employee.nil?

    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil
    name ||= "#{customer.name} Appointment"

    CustomerEmployeeAppointment.new(
      company: company,
      customer: customer,
      employee: employee,
      name: name,
      description: description || "Customer appointment for #{customer.name}.",
      code: code || "CUST-EMP-#{SecureRandom.hex(4).upcase}",
      discarded_at: discarded_at
    )
  end

  def self.create(...)
    appointment = new(...)
    appointment.save!
    appointment
  end
end
