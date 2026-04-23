# spec/factories/customer_groups.rb
FactoryBot.define do
  factory :customer_group do
    association :company

    initialize_with do
      Seed::CustomerGroupService.new(company: company)
    end

  end
end
