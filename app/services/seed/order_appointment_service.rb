class Seed::OrderAppointmentService
  def self.create(
    company:,
    order:,
    appoint_from: nil,
    appoint_to:,
    appoint_for: nil,
    appoint_by: nil,
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
    raise "Cannot create appointment: No company or order provided." if company.nil? || order.nil?

    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil
    name ||= "#{order.name} Appointment"

    OrderAppointment.create!(
      company: company,
      order: order,
      appoint_from: appoint_from,
      appoint_to: appoint_to,
      appoint_for: appoint_for,
      appoint_by: appoint_by,
      name: name,
      description: description || "Order appointment for #{order.name}.",
      code: code || "ORD-APT-#{SecureRandom.hex(4).upcase}",
      unit_price: unit_price || Faker::Commerce.price,
      quantity: quantity || rand(1..10),
      total_price: total_price,
      lifecycle_status: lifecycle_status || OrderAppointment.lifecycle_statuses.keys.sample,
      workflow_status: workflow_status || OrderAppointment.workflow_statuses.keys.sample,
      business_type: business_type || OrderAppointment.business_types.keys.sample,
      discarded_at: discarded_at
    )
  end
end
