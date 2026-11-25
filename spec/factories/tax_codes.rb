FactoryBot.define do
  factory :tax_code do
    association :company
    sequence(:name) { |n| "VAT #{n}%" }
    sequence(:code) { |n| "VAT#{n}" }
    kind { :vat }
    rate_bp { 1_000 }
    is_inclusive { false }
  end
end
