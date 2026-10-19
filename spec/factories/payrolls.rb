FactoryBot.define do
  factory :payroll do
    association :company
    association :employee
    month { Date.current.beginning_of_month }
    status { :draft }
    metadata { {} }
  end
end
