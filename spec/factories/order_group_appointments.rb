# spec/factories/order_group_appointments.rb
FactoryBot.define do
  factory :order_group_appointment do
    association :company
    association :order_group
    association :appoint_to, factory: :employee

    name { "#{order_group.name} Appointment" }
    description { "Order group appointment for #{order_group.name}." }
    code { "OGR-APT-#{SecureRandom.hex(4).upcase}" }
    unit_price { Faker::Commerce.price }
    quantity { rand(1..10) }
    lifecycle_status { OrderGroupAppointment.lifecycle_statuses.keys.sample }
    workflow_status { OrderGroupAppointment.workflow_statuses.keys.sample }
    business_type { OrderGroupAppointment.business_types.keys.sample }
    discarded_at { nil }

    initialize_with do
      Seed::OrderGroupAppointmentService.create(
        company: company,
        order_group: order_group,
        appoint_to: appoint_to,
        name: name,
        description: description,
        code: code,
        unit_price: unit_price,
        quantity: quantity,
        lifecycle_status: lifecycle_status,
        workflow_status: workflow_status,
        business_type: business_type,
        discarded_at: discarded_at
      )
    end

    skip_create
  end
end
