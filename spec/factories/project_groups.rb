# spec/factories/project_groups.rb
FactoryBot.define do
  factory :project_group do
    association :company
    association :branch, company: company

    initialize_with do
      Seed::ProjectGroupService.create(branch: branch)
    end

    skip_create
  end
end
