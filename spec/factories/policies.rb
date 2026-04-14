# spec/factories/policies.rb
FactoryBot.define do
  factory :policy do
    association :company
    association :branch, company: company

    initialize_with do
      Seed::PolicyService.create(branch: branch)
    end

    skip_create
  end
end
