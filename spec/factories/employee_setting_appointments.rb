# spec/factories/employee_setting_appointments.rb
FactoryBot.define do
  factory :employee_setting_appointment do
    association :company
    association :employee
    association :setting

    initialize_with do
      Seed::EmployeeSettingAppointmentService.new(company: company, employee: employee, setting: setting)
    end
  end
end
