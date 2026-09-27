class Seed::EmployeeOrderGroupAppointmentService
  def self.create(
    company:,
    order_group:,
    employee:,
    name: nil,
    description: nil,
    code: nil,
    unit_price: nil,
    quantity: nil,
    total_price: nil,
    lifecycle_status: nil,
    workflow_status: nil,
    business_type: nil,
    discarded_at: nil
  )
    raise "Cannot create appointment: No company or order_group provided." if company.nil? || order_group.nil?
    raise "Cannot create appointment: No employee provided." if employee.nil?

    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil
    name ||= "#{order_group.name} Appointment"

    EmployeeOrderGroupAppointment.create!(
      company: company,
      order_group: order_group,
      employee: employee,
      name: name,
      description: description || "Order group appointment for #{order_group.name}.",
      code: code || "OGR-APT-#{SecureRandom.hex(4).upcase}",
      unit_price: unit_price || Faker::Commerce.price,
      quantity: quantity || rand(1..10),
      total_price: total_price,
      lifecycle_status: lifecycle_status,
      workflow_status: workflow_status,
      business_type: business_type,
      discarded_at: discarded_at
    )
  end
end
