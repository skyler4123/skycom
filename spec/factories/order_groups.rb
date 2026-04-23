# spec/factories/order_groups.rb
FactoryBot.define do
  factory :order_group do
    association :company

    initialize_with do
      Seed::OrderGroupService.new(company: company)
    end

  end
end
