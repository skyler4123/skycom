# spec/factories/tasks.rb
FactoryBot.define do
  factory :task do
    association :company
    association :task_group

    initialize_with do
      Seed::TaskService.new(company: company, task_group: task_group)
    end
  end
end
