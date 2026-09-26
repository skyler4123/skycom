# spec/factories/article_employee_appointments.rb
FactoryBot.define do
  factory :article_employee_appointment do
    association :company
    association :article
    association :employee

    initialize_with do
      Seed::ArticleEmployeeAppointmentService.new(company: company, article: article, employee: employee)
    end
  end
end
