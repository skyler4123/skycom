# spec/factories/projects.rb
FactoryBot.define do
  factory :project do
    association :company
    association :project_group

    name { "Project #{Faker::Lorem.sentence(word_count: 3)}" }
    description { Faker::Lorem.sentence(word_count: 10) }
    code { "PROJ-#{SecureRandom.hex(4).upcase}" }
    lifecycle_status { Project.lifecycle_statuses.keys.sample }
    workflow_status { Project.workflow_statuses.keys.sample }
    business_type { Project.business_types.keys.sample }
    discarded_at { nil }

    initialize_with do
      Seed::ProjectService.new(
        company: company,
        project_group: project_group,
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
