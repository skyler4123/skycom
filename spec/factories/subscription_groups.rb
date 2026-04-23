# spec/factories/subscription_groups.rb
FactoryBot.define do
  factory :subscription_group do
    association :company

    initialize_with do
      Seed::SubscriptionGroupService.new(company: company)
    end

  end
end
