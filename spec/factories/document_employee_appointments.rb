# spec/factories/document_employee_appointments.rb
FactoryBot.define do
  factory :document_employee_appointment do
    association :company
    association :document
    association :employee

    initialize_with do
      Seed::DocumentEmployeeAppointmentService.new(company: company, document: document, employee: employee)
    end
  end
end
