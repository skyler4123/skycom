# spec/factories/role_tag_appointments.rb
FactoryBot.define do
  factory :role_tag_appointment do
    company
    tag { association :tag, company: company }
    role { association :role, company: company }
  end
end
