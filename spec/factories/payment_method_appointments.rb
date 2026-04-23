# spec/factories/payment_method_appointments.rb
FactoryBot.define do
  factory :payment_method_appointment do
    association :company
    association :payment_method

    name { "#{payment_method.name} Appointment" }
    description { "Payment method appointment for #{payment_method.name}." }
    code { "PM-APT-#{SecureRandom.hex(4).upcase}" }
    lifecycle_status { PaymentMethodAppointment.lifecycle_statuses.keys.sample }
    workflow_status { PaymentMethodAppointment.workflow_statuses.keys.sample }
    business_type { PaymentMethodAppointment.business_types.keys.sample }
    discarded_at { nil }

    initialize_with do
      Seed::PaymentMethodAppointmentService.new(
        company: company,
        payment_method: payment_method,
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
