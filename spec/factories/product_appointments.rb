# spec/factories/product_appointments.rb
FactoryBot.define do
  factory :product_appointment do
    association :company
    association :product
    association :appoint_to, factory: :employee

    name { "#{product.name} Appointment" }
    description { "Product appointment for #{product.name}." }
    code { "PROD-APT-#{SecureRandom.hex(4).upcase}" }
    lifecycle_status { ProductAppointment.lifecycle_statuses.keys.sample }
    workflow_status { ProductAppointment.workflow_statuses.keys.sample }
    business_type { ProductAppointment.business_types.keys.sample }
    discarded_at { nil }

    initialize_with do
      Seed::ProductAppointmentService.new(
        company: company,
        product: product,
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
