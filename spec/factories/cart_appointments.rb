# spec/factories/cart_appointments.rb
FactoryBot.define do
  factory :cart_appointment do
    association :company
    association :cart
    association :appoint_to, factory: :employee

    name { "#{cart.name} Appointment" }
    description { "Cart appointment for #{cart.name}." }
    code { "CART-APT-#{SecureRandom.hex(4).upcase}" }
    lifecycle_status { CartAppointment.lifecycle_statuses.keys.sample }
    workflow_status { CartAppointment.workflow_statuses.keys.sample }
    business_type { CartAppointment.business_types.keys.sample }
    discarded_at { nil }

    initialize_with do
      Seed::CartAppointmentService.create(
        company: company,
        cart: cart,
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

    skip_create
  end
end
