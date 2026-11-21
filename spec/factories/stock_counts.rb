# spec/factories/stock_counts.rb
FactoryBot.define do
  factory :stock_count do
    association :company
    warehouse { association :warehouse, company: company }
    association :created_by_employee, factory: :employee, company: company

    count_type { :cycle }
    status { :draft }
  end
end
