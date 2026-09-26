# spec/factories/employee_tag_appointments.rb
FactoryBot.define do
  factory :employee_tag_appointment do
    company
    tag { association :tag, company: company }
    employee { association :employee, company: company }
  end
end
