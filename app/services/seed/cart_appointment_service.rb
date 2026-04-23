class Seed::CartAppointmentService
  def self.new(
    company:,
    cart:,
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
    raise "Cannot create appointment: No company or cart provided." if company.nil? || cart.nil?

    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil
    name ||= "#{cart.name} Appointment"

    CartAppointment.new(
      company: company,
      cart: cart,
      appoint_from: appoint_from,
      appoint_to: appoint_to,
      appoint_for: appoint_for,
      appoint_by: appoint_by,
      name: name,
      description: description || "Cart appointment for #{cart.name}.",
      code: code || "CART-APT-#{SecureRandom.hex(4).upcase}",
      lifecycle_status: lifecycle_status || CartAppointment.lifecycle_statuses.keys.sample,
      workflow_status: workflow_status || CartAppointment.workflow_statuses.keys.sample,
      business_type: business_type || CartAppointment.business_types.keys.sample,
      discarded_at: discarded_at
    )
  end

  def self.create(...)
    appointment = new(...)
    appointment.save!
    appointment
  end
end
