# spec/factories/discount_groups.rb
FactoryBot.define do
  factory :discount_group do
    association :company
    name { "Discount Group #{SecureRandom.hex(4)}" }
    prefix { "DSC" }
    discount_type { :percentage }
    percentage { 10 }

    initialize_with do
      Seed::DiscountGroupService.new(
        company: company,
        name: name,
        prefix: prefix,
        discount_type: discount_type,
        percentage: percentage
      )
    end
  end
end
