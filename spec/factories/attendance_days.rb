# spec/factories/attendance_days.rb
FactoryBot.define do
  factory :attendance_day do
    association :company
    association :employee

    initialize_with do
      AttendanceDay.create!(
        company: company,
        employee: employee,
        attendance_date: Date.current,
        attendance_status: :present,
        total_seconds_worked: 28800
      )
    end
  end
end
