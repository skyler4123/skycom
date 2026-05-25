# spec/factories/subscription_group_appointments.rb
FactoryBot.define do
  factory :subscription_group_appointment do
    association :company
    association :subscription_group
    association :appoint_to, factory: :employee

    initialize_with do
      Seed::SubscriptionGroupAppointmentService.new(company: company, subscription_group: subscription_group, appoint_to: appoint_to)
    end
  end
end
