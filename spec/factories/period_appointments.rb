# spec/factories/period_appointments.rb
FactoryBot.define do
  factory :period_appointment do
    association :period
    association :appoint_to, factory: :employee

    initialize_with do
      Seed::PeriodAppointmentService.new(period: period, appoint_to: appoint_to)
    end
  end
end
