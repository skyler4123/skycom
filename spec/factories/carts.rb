# spec/factories/carts.rb
FactoryBot.define do
  factory :cart do
    association :company
    association :branch, company: company

    initialize_with do
      Seed::CartService.new(branch: branch)
    end

  end
end
