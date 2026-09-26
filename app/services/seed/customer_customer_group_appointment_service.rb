class Seed::CustomerCustomerGroupAppointmentService
  def self.new(
    company:,
    customer:,
    customer_group:,
    name: nil,
    description: nil,
    code: nil,
    discarded_at: nil
  )
    raise "Cannot create appointment: No company, customer or customer_group provided." if company.nil? || customer.nil? || customer_group.nil?

    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil
    name ||= "#{customer.name} Appointment"

    CustomerCustomerGroupAppointment.new(
      company: company,
      customer: customer,
      customer_group: customer_group,
      name: name,
      description: description || "Customer appointment for #{customer.name}.",
      code: code || "CCG-#{SecureRandom.hex(4).upcase}",
      discarded_at: discarded_at
    )
  end

  def self.create(...)
    appointment = new(...)
    appointment.save!
    appointment
  end
end
