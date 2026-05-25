# spec/factories/projects.rb
FactoryBot.define do
  factory :project do
    association :company
    association :project_group

    initialize_with do
      Seed::ProjectService.new(company: company, project_group: project_group)
    end
  end
end
