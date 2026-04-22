# spec/factories/order_appointments.rb
FactoryBot.define do
  factory :order_appointment do
    association :company
    association :order
    association :appoint_to, factory: :employee

    name { "#{order.name} Appointment" }
    description { "Order appointment for #{order.name}." }
    code { "ORD-APT-#{SecureRandom.hex(4).upcase}" }
    unit_price { Faker::Commerce.price }
    quantity { rand(1..10) }
    lifecycle_status { OrderAppointment.lifecycle_statuses.keys.sample }
    workflow_status { OrderAppointment.workflow_statuses.keys.sample }
    business_type { OrderAppointment.business_types.keys.sample }
    discarded_at { nil }

    initialize_with do
      Seed::OrderAppointmentService.create(
        company: company,
        order: order,
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
