# spec/factories/notification_group_appointments.rb
FactoryBot.define do
  factory :notification_group_appointment do
    association :company
    association :notification_group
    association :appoint_to, factory: :employee

    initialize_with do
      Seed::NotificationGroupAppointmentService.new(company: company, notification_group: notification_group, appoint_to: appoint_to)
    end
  end
end
