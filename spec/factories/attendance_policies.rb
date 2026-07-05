# spec/factories/attendance_policies.rb
FactoryBot.define do
  factory :attendance_policy do
    association :company
    association :branch

    initialize_with do
      AttendancePolicy.create!(
        company: company,
        branch: branch,
        latitude: 10.773,
        longitude: 106.694,
        allowed_radius_meters: 100,
        resolution_strategy: :paired
      )
    end
  end
end
