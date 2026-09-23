# spec/factories/discounts.rb
FactoryBot.define do
  factory :discount do
    discount_group { association :discount_group }
    company { discount_group.company }
    code { "DSC-#{SecureRandom.hex(4)}" }

    initialize_with do
      Seed::DiscountService.new(company: company, discount_group: discount_group, code: code)
    end
  end
end
