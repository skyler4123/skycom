# spec/factories/scheduled_shifts.rb
FactoryBot.define do
  factory :scheduled_shift do
    association :company
    association :branch
    association :employee

    initialize_with do
      ScheduledShift.create!(
        company: company,
        branch: branch,
        employee: employee,
        work_date: Date.current,
        expected_start_at: Time.current.change(hour: 9),
        expected_end_at: Time.current.change(hour: 18),
        status: "scheduled"
      )
    end
  end
end
