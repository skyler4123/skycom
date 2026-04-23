class Seed::OrderGroupAppointmentService
  def self.create(
    company:,
    order_group:,
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
    raise "Cannot create appointment: No company or order_group provided." if company.nil? || order_group.nil?

    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil
    name ||= "#{order_group.name} Appointment"

    OrderGroupAppointment.create!(
      company: company,
      order_group: order_group,
      appoint_from: appoint_from,
      appoint_to: appoint_to,
      appoint_for: appoint_for,
      appoint_by: appoint_by,
      name: name,
      description: description || "Order group appointment for #{order_group.name}.",
      code: code || "OGR-APT-#{SecureRandom.hex(4).upcase}",
      unit_price: unit_price || Faker::Commerce.price,
      quantity: quantity || rand(1..10),
      total_price: total_price,
      lifecycle_status: lifecycle_status || OrderGroupAppointment.lifecycle_statuses.keys.sample,
      workflow_status: workflow_status || OrderGroupAppointment.workflow_statuses.keys.sample,
      business_type: business_type || OrderGroupAppointment.business_types.keys.sample,
      discarded_at: discarded_at
    )
  end
end
