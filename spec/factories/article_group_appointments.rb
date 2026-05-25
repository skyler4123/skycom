# spec/factories/article_group_appointments.rb
FactoryBot.define do
  factory :article_group_appointment do
    association :company
    association :article_group
    association :appoint_to, factory: :employee

    initialize_with do
      Seed::ArticleGroupAppointmentService.new(company: company, article_group: article_group, appoint_to: appoint_to)
    end
  end
end
