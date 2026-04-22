# spec/factories/customer_appointments.rb
FactoryBot.define do
  factory :customer_appointment do
    association :company
    association :customer
    association :appoint_to, factory: :employee

    name { "#{customer.name} Appointment" }
    description { "Customer appointment for #{customer.name}." }
    code { "CUST-APT-#{SecureRandom.hex(4).upcase}" }
    lifecycle_status { CustomerAppointment.lifecycle_statuses.keys.sample }
    workflow_status { CustomerAppointment.workflow_statuses.keys.sample }
    business_type { CustomerAppointment.business_types.keys.sample }
    discarded_at { nil }

    initialize_with do
      Seed::CustomerAppointmentService.create(
        company: company,
        customer: customer,
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
