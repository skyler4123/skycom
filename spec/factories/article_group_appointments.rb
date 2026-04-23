# spec/factories/article_group_appointments.rb
FactoryBot.define do
  factory :article_group_appointment do
    association :company
    association :article_group
    association :appoint_to, factory: :employee

    name { "#{article_group.name} Appointment" }
    description { "Article group appointment for #{article_group.name}." }
    code { "AGR-APT-#{SecureRandom.hex(4).upcase}" }
    lifecycle_status { ArticleGroupAppointment.lifecycle_statuses.keys.sample }
    workflow_status { ArticleGroupAppointment.workflow_statuses.keys.sample }
    business_type { ArticleGroupAppointment.business_types.keys.sample }
    discarded_at { nil }

    initialize_with do
      Seed::ArticleGroupAppointmentService.new(
        company: company,
        article_group: article_group,
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
