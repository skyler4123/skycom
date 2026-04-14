# spec/factories/order_groups.rb
FactoryBot.define do
  factory :order_group do
    association :company

    initialize_with do
      Seed::OrderGroupService.create(company: company)
    end

    skip_create
  end
end
