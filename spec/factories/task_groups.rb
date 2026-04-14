# spec/factories/task_groups.rb
FactoryBot.define do
  factory :task_group do
    association :company
    association :branch, company: company

    initialize_with do
      Seed::TaskGroupService.create(branch: branch)
    end

    skip_create
  end
end
