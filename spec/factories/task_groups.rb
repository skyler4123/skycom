# spec/factories/task_groups.rb
FactoryBot.define do
  factory :task_group do
    association :company
    association :branch, company: company

    initialize_with do
      Seed::TaskGroupService.new(branch: branch)
    end

  end
end
