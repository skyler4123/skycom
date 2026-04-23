# spec/factories/subscription_group_appointments.rb
FactoryBot.define do
  factory :subscription_group_appointment do
    association :company
    association :subscription_group
    association :appoint_to, factory: :employee

    name { "#{subscription_group.name} Appointment" }
    description { "Subscription group appointment for #{subscription_group.name}." }
    code { "SGR-APT-#{SecureRandom.hex(4).upcase}" }
    lifecycle_status { SubscriptionGroupAppointment.lifecycle_statuses.keys.sample }
    workflow_status { SubscriptionGroupAppointment.workflow_statuses.keys.sample }
    business_type { SubscriptionGroupAppointment.business_types.keys.sample }
    discarded_at { nil }

    initialize_with do
      Seed::SubscriptionGroupAppointmentService.new(
        company: company,
        subscription_group: subscription_group,
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
