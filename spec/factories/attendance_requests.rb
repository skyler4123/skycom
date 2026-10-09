# spec/factories/attendance_requests.rb
FactoryBot.define do
  factory :attendance_request do
    association :company
    employee { association :employee, company: company }
    attendance_date { Date.yesterday }
    check_in { Time.zone.parse("#{Date.yesterday} 09:00") }
    check_out { Time.zone.parse("#{Date.yesterday} 17:00") }
    reason { "Field work - no GPS" }
    status { :pending }
  end
end
