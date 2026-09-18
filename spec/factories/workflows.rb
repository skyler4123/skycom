# spec/factories/workflows.rb
FactoryBot.define do
  factory :workflow do
    association :company
    name { "Workflow #{SecureRandom.hex(4)}" }
    process_type { :purchase_process }
    is_default { false }

    initialize_with do
      Seed::WorkflowService.new(
        company: company,
        name: name,
        process_type: process_type,
        is_default: is_default
      )
    end
  end
end
