# spec/factories/policies.rb
FactoryBot.define do
  factory :policy do
    association :branch

    initialize_with do
      Seed::PolicyService.create(branch: branch)
    end

    skip_create
  end
end
