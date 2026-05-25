# spec/factories/subscription_appointments.rb
FactoryBot.define do
  factory :subscription_appointment do
    association :company
    association :subscription
    association :appoint_to, factory: :employee

    initialize_with do
      Seed::SubscriptionAppointmentService.new(company: company, subscription: subscription, appoint_to: appoint_to)
    end
  end
end
