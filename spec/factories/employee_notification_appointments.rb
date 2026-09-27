# spec/factories/employee_notification_appointments.rb
FactoryBot.define do
  factory :employee_notification_appointment do
    association :company
    association :employee
    association :notification

    initialize_with do
      Seed::EmployeeNotificationAppointmentService.new(company: company, employee: employee, notification: notification)
    end
  end
end
