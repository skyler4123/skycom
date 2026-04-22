# spec/factories/customer_group_appointments.rb
FactoryBot.define do
  factory :customer_group_appointment do
    association :company
    association :customer_group
    association :appoint_to, factory: :employee

    name { "#{customer_group.name} Appointment" }
    description { "Customer group appointment for #{customer_group.name}." }
    code { "CGR-APT-#{SecureRandom.hex(4).upcase}" }
    lifecycle_status { CustomerGroupAppointment.lifecycle_statuses.keys.sample }
    workflow_status { CustomerGroupAppointment.workflow_statuses.keys.sample }
    business_type { CustomerGroupAppointment.business_types.keys.sample }
    discarded_at { nil }

    initialize_with do
      Seed::CustomerGroupAppointmentService.create(
        customer_group: customer_group,
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
