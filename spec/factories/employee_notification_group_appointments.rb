# spec/factories/employee_notification_group_appointments.rb
FactoryBot.define do
  factory :employee_notification_group_appointment do
    association :company
    association :employee
    association :notification_group

    initialize_with do
      Seed::EmployeeNotificationGroupAppointmentService.new(company: company, employee: employee, notification_group: notification_group)
    end
  end
end
