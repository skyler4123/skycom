class Seed::ProductProductGroupAppointmentService
  def self.new(
    company:,
    product:,
    product_group:,
    name: nil,
    description: nil,
    code: nil,
    discarded_at: nil
  )
    raise "Cannot create appointment: No company, product or product_group provided." if company.nil? || product.nil? || product_group.nil?

    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil
    name ||= "#{product.name} Appointment"

    ProductProductGroupAppointment.new(
      company: company,
      product: product,
      product_group: product_group,
      name: name,
      description: description || "Product appointment for #{product.name}.",
      code: code || "PPG-#{SecureRandom.hex(4).upcase}",
      discarded_at: discarded_at
    )
  end

  def self.create(...)
    appointment = new(...)
    appointment.save!
    appointment
  end
end
