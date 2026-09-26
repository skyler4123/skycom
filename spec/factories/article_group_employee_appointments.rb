# spec/factories/article_group_employee_appointments.rb
FactoryBot.define do
  factory :article_group_employee_appointment do
    association :company
    association :article_group
    association :employee

    initialize_with do
      Seed::ArticleGroupEmployeeAppointmentService.new(company: company, article_group: article_group, employee: employee)
    end
  end
end
