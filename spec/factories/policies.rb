# spec/factories/policies.rb
FactoryBot.define do
  factory :policy do
    association :company
    association :branch, company: company

    initialize_with do
      Seed::PolicyService.new(branch: branch)
    end

  end
end
