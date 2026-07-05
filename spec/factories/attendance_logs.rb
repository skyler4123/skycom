# spec/factories/attendance_logs.rb
FactoryBot.define do
  factory :attendance_log do
    association :company
    association :employee

    initialize_with do
      AttendanceLog.create!(
        company: company,
        employee: employee,
        log_type: "check_in",
        logged_at: Time.current
      )
    end
  end
end
