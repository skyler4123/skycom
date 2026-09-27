class Seed::OrderProductAppointmentService
  def self.new(
    company:,
    order:,
    product:,
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
    raise "Cannot create appointment: No product provided." if product.nil?

    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil
    name ||= "#{order.name} Appointment"
    quantity ||= rand(1..10)
    unit_price ||= Faker::Commerce.price

    OrderProductAppointment.new(
      company: company,
      order: order,
      product: product,
      name: name,
      description: description || "Order appointment for #{order.name}.",
      code: code || "ORD-APT-#{SecureRandom.hex(4).upcase}",
      unit_price: unit_price,
      quantity: quantity,
      total_price: total_price || (quantity * unit_price),
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
