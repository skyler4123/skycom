# spec/factories/customer_groups.rb
FactoryBot.define do
  factory :customer_group do
    association :company

    initialize_with do
      Seed::CustomerGroupService.create(company: company)
    end

    skip_create
  end
end
