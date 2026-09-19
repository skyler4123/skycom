# spec/factories/workflow_step_logs.rb
FactoryBot.define do
  factory :workflow_step_log do
    association :workflow
    workflow_step { association :workflow_step, workflow: workflow }
    subject { association :purchase, company: workflow.company }
    employee { association :employee, company: workflow.company }
    outcome { :submitted }

    initialize_with do
      WorkflowStepLog.new(
        company: workflow.company,
        workflow: workflow,
        workflow_step: workflow_step,
        subject: subject,
        employee: employee,
        outcome: outcome
      )
    end
  end
end
