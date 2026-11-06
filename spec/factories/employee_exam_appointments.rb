# spec/factories/employee_exam_appointments.rb
FactoryBot.define do
  factory :employee_exam_appointment do
    association :exam
    employee { association :employee, company: exam.company }
    attempt_number { 1 }
    workflow_status { :assigned }
  end
end
