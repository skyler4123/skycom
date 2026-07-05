# spec/factories/attendance_months.rb
FactoryBot.define do
  factory :attendance_month do
    association :company
    association :employee

    initialize_with do
      AttendanceMonth.create!(
        company: company,
        employee: employee,
        month: Date.current.beginning_of_month,
        total_work_minutes: 9600,
        total_present_days: 20,
        total_absent_days: 2
      )
    end
  end
end
