# spec/factories/subscription_appointments.rb
FactoryBot.define do
  factory :subscription_appointment do
    association :company
    association :subscription
    association :appoint_to, factory: :employee

    name { "#{subscription.name} Appointment" }
    description { "Subscription appointment for #{subscription.name}." }
    code { "SUB-APT-#{SecureRandom.hex(4).upcase}" }
    lifecycle_status { SubscriptionAppointment.lifecycle_statuses.keys.sample }
    workflow_status { SubscriptionAppointment.workflow_statuses.keys.sample }
    business_type { SubscriptionAppointment.business_types.keys.sample }
    discarded_at { nil }

    initialize_with do
      Seed::SubscriptionAppointmentService.new(
        company: company,
        subscription: subscription,
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
