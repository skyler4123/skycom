class Seed::InventoryTransactionAppointmentService
  def self.new(
    company:,
    inventory_transaction:,
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
    raise "Cannot create appointment: No company or inventory_transaction provided." if company.nil? || inventory_transaction.nil?

    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil
    name ||= "#{inventory_transaction.name} Appointment"

    InventoryTransactionAppointment.new(
      company: company,
      inventory_transaction: inventory_transaction,
      appoint_from: appoint_from,
      appoint_to: appoint_to,
      appoint_for: appoint_for,
      appoint_by: appoint_by,
      name: name,
      description: description || "Inventory transaction appointment for #{inventory_transaction.name}.",
      code: code || "INVTXN-APT-#{SecureRandom.hex(4).upcase}",
      lifecycle_status: lifecycle_status || InventoryTransactionAppointment.lifecycle_statuses.keys.sample,
      workflow_status: workflow_status || InventoryTransactionAppointment.workflow_statuses.keys.sample,
      business_type: business_type || InventoryTransactionAppointment.business_types.keys.sample,
      discarded_at: discarded_at
    )
  end

  def self.create(...)
    appointment = new(...)
    appointment.save!
    appointment
  end
end
