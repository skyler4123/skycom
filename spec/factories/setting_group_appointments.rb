# spec/factories/setting_group_appointments.rb
FactoryBot.define do
  factory :setting_group_appointment do
    association :company
    association :setting_group
    association :appoint_to, factory: :employee

    initialize_with do
      Seed::SettingGroupAppointmentService.new(company: company, setting_group: setting_group, appoint_to: appoint_to)
    end
  end
end
