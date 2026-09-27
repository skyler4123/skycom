# spec/factories/document_group_employee_appointments.rb
FactoryBot.define do
  factory :document_group_employee_appointment do
    association :company
    association :document_group
    association :employee

    initialize_with do
      Seed::DocumentGroupEmployeeAppointmentService.new(company: company, document_group: document_group, employee: employee)
    end
  end
end
