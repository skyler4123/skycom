# frozen_string_literal: true

FactoryBot.define do
  factory :leave_request do
    association :company
    employee { association :employee, company: company }
    leave_type { :paid }
    status { :pending }
    start_date { Date.current - 10.days }
    end_date { start_date + 1.day }
    days { 2.0 }
    reason { "Family trip" }
  end
end
