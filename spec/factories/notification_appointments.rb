# spec/factories/notification_appointments.rb
FactoryBot.define do
  factory :notification_appointment do
    association :company
    association :notification
    association :appoint_to, factory: :employee

    initialize_with do
      Seed::NotificationAppointmentService.new(company: company, notification: notification, appoint_to: appoint_to)
    end
  end
end
