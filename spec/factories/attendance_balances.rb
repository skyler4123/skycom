# frozen_string_literal: true

FactoryBot.define do
  factory :attendance_balance do
    association :company
    employee { association :employee, company: company }
    year { Date.current.year }
    entitled_days { 14.0 }
  end
end
