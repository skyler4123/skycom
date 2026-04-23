# spec/factories/inventory_item_appointments.rb
FactoryBot.define do
  factory :inventory_item_appointment do
    association :company
    association :inventory_item
    association :appoint_to, factory: :employee

    name { "#{inventory_item.name} Appointment" }
    description { "Inventory item appointment for #{inventory_item.name}." }
    code { "INVIT-APT-#{SecureRandom.hex(4).upcase}" }
    lifecycle_status { InventoryItemAppointment.lifecycle_statuses.keys.sample }
    workflow_status { InventoryItemAppointment.workflow_statuses.keys.sample }
    business_type { InventoryItemAppointment.business_types.keys.sample }
    discarded_at { nil }

    initialize_with do
      Seed::InventoryItemAppointmentService.new(
        company: company,
        inventory_item: inventory_item,
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
