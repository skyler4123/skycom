# spec/factories/setting_appointments.rb
FactoryBot.define do
  factory :setting_appointment do
    association :company
    association :setting
    association :appoint_to, factory: :employee

    initialize_with do
      Seed::SettingAppointmentService.new(company: company, setting: setting, appoint_to: appoint_to)
    end
  end
end
