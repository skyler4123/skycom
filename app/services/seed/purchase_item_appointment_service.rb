class Seed::PurchaseItemAppointmentService
  def self.new(
    company:,
    purchase:,
    purchase_item:,
    quantity: nil,
    unit_price: nil,
    total_price: nil,
    name: nil,
    description: nil,
    code: nil,
    lifecycle_status: :active,
    discarded_at: nil
  )
    raise "Cannot create appointment: No company or purchase provided." if company.nil? || purchase.nil?

    quantity ||= rand(1..20)
    unit_price ||= purchase_item&.estimated_unit_price || Faker::Commerce.price(range: 0.5..50.0)

    PurchaseItemAppointment.new(
      company: company,
      purchase_item: purchase_item,
      appoint_to: purchase,
      name: name,
      description: description || "Line item for #{purchase.name}.",
      code: code || "PUR-APT-#{SecureRandom.hex(4).upcase}",
      quantity: quantity,
      unit_price: unit_price,
      total_price: total_price || (quantity * unit_price),
      lifecycle_status: lifecycle_status,
      discarded_at: discarded_at
    )
  end

  def self.create(...)
    appointment = new(...)
    appointment.save!
    appointment
  end
end
