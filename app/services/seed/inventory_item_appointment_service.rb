class Seed::InventoryItemAppointmentService
  def self.new(
    company:,
    inventory_item:,
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
    raise "Cannot create appointment: No company or inventory_item provided." if company.nil? || inventory_item.nil?

    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil
    name ||= "#{inventory_item.name} Appointment"

    InventoryItemAppointment.new(
      company: company,
      inventory_item: inventory_item,
      appoint_from: appoint_from,
      appoint_to: appoint_to,
      appoint_for: appoint_for,
      appoint_by: appoint_by,
      name: name,
      description: description || "Inventory item appointment for #{inventory_item.name}.",
      code: code || "INVIT-APT-#{SecureRandom.hex(4).upcase}",
      lifecycle_status: lifecycle_status || InventoryItemAppointment.lifecycle_statuses.keys.sample,
      workflow_status: workflow_status || InventoryItemAppointment.workflow_statuses.keys.sample,
      business_type: business_type || InventoryItemAppointment.business_types.keys.sample,
      discarded_at: discarded_at
    )
  end

  def self.create(...)
    appointment = new(...)
    appointment.save!
    appointment
  end
end
