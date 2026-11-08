# spec/factories/operations.rb
FactoryBot.define do
  factory :operation do
    association :company

    transient do
      branch { nil }
    end

    operation_type { :pos }
    name { "#{operation_type.to_s.humanize} Operation" }
    code { "OP-#{SecureRandom.hex(4).upcase}" }
    metadata { { "roles" => [] } }
    lifecycle_status { :active }
    workflow_status { :approved }

    initialize_with do
      Operation.find_or_initialize_by(
        company: company,
        operation_type: operation_type
      ).tap do |record|
        if record.new_record?
          record.name = name
          record.code = code
          record.metadata = metadata
          record.lifecycle_status = lifecycle_status
          record.workflow_status = workflow_status
        end
      end
    end

    after(:create) do |operation, evaluator|
      next unless evaluator.branch

      BranchOperationAppointment.find_or_create_by!(
        company: operation.company,
        branch: evaluator.branch,
        operation: operation
      )
    end
  end
end
