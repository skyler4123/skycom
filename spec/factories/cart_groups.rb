# spec/factories/cart_groups.rb
FactoryBot.define do
  factory :cart_group do
    association :company
    association :branch, company: company

    initialize_with do
      Seed::CartGroupService.create(branch: branch)
    end

    skip_create
  end
end
