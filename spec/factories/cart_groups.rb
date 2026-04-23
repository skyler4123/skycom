# spec/factories/cart_groups.rb
FactoryBot.define do
  factory :cart_group do
    association :company
    association :branch, company: company

    initialize_with do
      Seed::CartGroupService.new(branch: branch)
    end
  end
end
