# spec/factories/employee_setting_group_appointments.rb
FactoryBot.define do
  factory :employee_setting_group_appointment do
    association :company
    association :employee
    association :setting_group

    initialize_with do
      Seed::EmployeeSettingGroupAppointmentService.new(company: company, employee: employee, setting_group: setting_group)
    end
  end
end
