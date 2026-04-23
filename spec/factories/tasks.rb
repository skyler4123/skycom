# spec/factories/tasks.rb
FactoryBot.define do
  factory :task do
    association :company
    association :task_group

    name { "Task #{Faker::Lorem.sentence(word_count: 3)}" }
    description { Faker::Lorem.sentence(word_count: 10) }
    code { "TSK-#{SecureRandom.hex(4).upcase}" }
    currency_code { Task.currency_codes.keys.sample }
    lifecycle_status { Task.lifecycle_statuses.keys.sample }
    workflow_status { Task.workflow_statuses.keys.sample }
    business_type { Task.business_types.keys.sample }
    discarded_at { nil }

    initialize_with do
      Seed::TaskService.new(
        task_group: task_group,
        name: name,
        description: description,
        code: code,
        currency_code: currency_code,
        lifecycle_status: lifecycle_status,
        workflow_status: workflow_status,
        business_type: business_type,
        discarded_at: discarded_at
      )
    end

  end
end
