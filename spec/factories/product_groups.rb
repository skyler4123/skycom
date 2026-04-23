# spec/factories/product_groups.rb
FactoryBot.define do
  factory :product_group do
    association :company
    association :branch, company: company

    initialize_with do
      Seed::ProductGroupService.new(branch: branch)
    end
  end
end
