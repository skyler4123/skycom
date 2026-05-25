# spec/factories/article_appointments.rb
FactoryBot.define do
  factory :article_appointment do
    association :company
    association :article
    association :appoint_to, factory: :employee

    initialize_with do
      Seed::ArticleAppointmentService.new(company: company, article: article, appoint_to: appoint_to)
    end
  end
end
