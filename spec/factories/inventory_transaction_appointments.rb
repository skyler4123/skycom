# spec/factories/inventory_transaction_appointments.rb
FactoryBot.define do
  factory :inventory_transaction_appointment do
    association :company
    association :inventory_transaction
    association :appoint_to, factory: :employee

    name { "#{inventory_transaction.name} Appointment" }
    description { "Inventory transaction appointment for #{inventory_transaction.name}." }
    code { "INVTXN-APT-#{SecureRandom.hex(4).upcase}" }
    lifecycle_status { InventoryTransactionAppointment.lifecycle_statuses.keys.sample }
    workflow_status { InventoryTransactionAppointment.workflow_statuses.keys.sample }
    business_type { InventoryTransactionAppointment.business_types.keys.sample }
    discarded_at { nil }

    initialize_with do
      Seed::InventoryTransactionAppointmentService.new(
        company: company,
        inventory_transaction: inventory_transaction,
        appoint_to: appoint_to,
        name: name,
        description: description,
        code: code,
        lifecycle_status: lifecycle_status,
        workflow_status: workflow_status,
        business_type: business_type,
        discarded_at: discarded_at
      )
    end

  end
end
