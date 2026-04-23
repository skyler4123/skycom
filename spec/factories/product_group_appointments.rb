# spec/factories/product_group_appointments.rb
FactoryBot.define do
  factory :product_group_appointment do
    association :company
    association :product_group
    association :appoint_to, factory: :employee

    name { "#{product_group.name} Appointment" }
    description { "Product group appointment for #{product_group.name}." }
    code { "PGR-APT-#{SecureRandom.hex(4).upcase}" }
    lifecycle_status { ProductGroupAppointment.lifecycle_statuses.keys.sample }
    workflow_status { ProductGroupAppointment.workflow_statuses.keys.sample }
    business_type { ProductGroupAppointment.business_types.keys.sample }
    discarded_at { nil }

    initialize_with do
      Seed::ProductGroupAppointmentService.new(
        company: company,
        product_group: product_group,
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
