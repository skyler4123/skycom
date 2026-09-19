# spec/factories/workflow_steps.rb
FactoryBot.define do
  sequence(:workflow_step_position) { |n| n }

  factory :workflow_step do
    association :workflow
    name { "Step #{SecureRandom.hex(4)}" }
    position { FactoryBot.generate(:workflow_step_position) }

    initialize_with do
      Seed::WorkflowStepService.new(
        company: workflow.company,
        workflow: workflow,
        name: name,
        position: position
      )
    end
  end
end
