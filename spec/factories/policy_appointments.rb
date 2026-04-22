FactoryBot.define do
  factory :policy_appointment do
    association :policy
    association :appoint_to, factory: :role
    workflow_status { :active }
  end
end
