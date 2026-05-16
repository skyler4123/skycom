# spec/factories/department_appointments.rb
FactoryBot.define do
  factory :department_appointment do
    association :department
    association :appoint_to, factory: :employee

    name { "#{department.name} Appointment" }
    description { "Department appointment for #{department.name}." }
    lifecycle_status { :active }
  end
end
