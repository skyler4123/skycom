# spec/factories/policy_appointments.rb
FactoryBot.define do
  factory :policy_appointment do
    association :policy
    association :appoint_to, factory: :employee

    initialize_with do
      Seed::PolicyAppointmentService.new(policy: policy, appoint_to: appoint_to)
    end
  end
end
