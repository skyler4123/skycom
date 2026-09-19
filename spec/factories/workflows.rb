# spec/factories/workflows.rb
FactoryBot.define do
  factory :workflow do
    association :company
    category { association :category, company: company }
    name { "Workflow #{SecureRandom.hex(4)}" }
    process_type { :purchase_process }

    initialize_with do
      Seed::WorkflowService.new(
        company: company,
        category: category,
        name: name,
        process_type: process_type
      )
    end
  end
end
