# spec/factories/article_appointments.rb
FactoryBot.define do
  factory :article_appointment do
    association :company
    association :article
    association :appoint_to, factory: :employee

    name { "#{article.name} Appointment" }
    description { "Article appointment for #{article.name}." }
    code { "ART-APT-#{SecureRandom.hex(4).upcase}" }
    lifecycle_status { ArticleAppointment.lifecycle_statuses.keys.sample }
    workflow_status { ArticleAppointment.workflow_statuses.keys.sample }
    business_type { ArticleAppointment.business_types.keys.sample }
    discarded_at { nil }

    initialize_with do
      Seed::ArticleAppointmentService.new(
        company: company,
        article: article,
        appoint_to: appoint_to,
        name: name,
        description: description,
        code: code,
        lifecycle_status: lifecycle_status,
        workflow_status: workflow_status,
        business_type: business_type,
        discarded_at: discarded_at
      )
    end

  end
end
