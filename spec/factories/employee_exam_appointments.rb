# spec/factories/employee_exam_appointments.rb
FactoryBot.define do
  factory :employee_exam_appointment do
    association :company
    association :employee
    association :exam

    initialize_with do
      Seed::EmployeeExamAppointmentService.new(company: company, employee: employee, exam: exam)
    end
  end
end
