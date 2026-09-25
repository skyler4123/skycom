class Seed::CartEmployeeAppointmentService
  def self.new(
    company:,
    cart:,
    employee:,
    name: nil,
    description: nil,
    code: nil,
    lifecycle_status: nil,
    workflow_status: nil,
    business_type: nil,
    discarded_at: nil
  )
    raise "Cannot create appointment: No company or cart provided." if company.nil? || cart.nil?
    raise "Cannot create appointment: No employee provided." if employee.nil?

    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil
    name ||= "#{cart.name} Appointment"

    CartEmployeeAppointment.new(
      company: company,
      cart: cart,
      employee: employee,
      name: name,
      description: description || "Cart appointment for #{cart.name}.",
      code: code || "CART-APT-#{SecureRandom.hex(4).upcase}",
      lifecycle_status: lifecycle_status,
      workflow_status: workflow_status,
      business_type: business_type,
      discarded_at: discarded_at
    )
  end

  def self.create(...)
    appointment = new(...)
    appointment.save!
    appointment
  end
end
