class Seed::CustomerAppointmentService
  def self.new(
    company:,
    customer:,
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
    raise "Cannot create appointment: No company or customer provided." if company.nil? || customer.nil?

    attrs = {
      company: company,
      name: name,
      description: description,
      code: code,
      discarded_at: discarded_at
    }
    case appoint_to
    when Employee
      Seed::CustomerEmployeeAppointmentService.new(**attrs, customer: customer, employee: appoint_to)
    when Service
      Seed::CustomerServiceAppointmentService.new(**attrs, customer: customer, service: appoint_to)
    when CustomerGroup
      Seed::CustomerCustomerGroupAppointmentService.new(**attrs, customer: customer, customer_group: appoint_to)
    when Membership
      CustomerMembershipAppointment.new(
        company: company,
        customer: customer,
        membership: appoint_to,
        name: attrs[:name] || "#{customer.name} Appointment",
        description: attrs[:description] || "Customer appointment for #{customer.name}.",
        code: attrs[:code] || "CUST-MEM-#{SecureRandom.hex(4).upcase}",
        lifecycle_status: lifecycle_status || :active,
        workflow_status: workflow_status || :approved,
        business_type: business_type || :primary,
        discarded_at: attrs[:discarded_at]
      )
    when Reservation
      CustomerReservationAppointment.new(
        company: company,
        customer: customer,
        reservation: appoint_to,
        name: attrs[:name] || "#{customer.name} Appointment",
        description: attrs[:description] || "Customer appointment for #{customer.name}.",
        code: attrs[:code] || "CUST-RES-#{SecureRandom.hex(4).upcase}",
        lifecycle_status: lifecycle_status || :active,
        workflow_status: workflow_status || :draft,
        business_type: business_type || :primary,
        discarded_at: attrs[:discarded_at]
      )
    else
      raise "Cannot route CustomerAppointment for #{appoint_to.class.name}: no atomic pair table."
    end
  end

  def self.create(...)
    appointment = new(...)
    appointment.save!
    appointment
  end
end
