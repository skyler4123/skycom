class Seed::WorkflowService
  def self.new(
    company:,
    name:,
    description: nil,
    code: nil,
    process_type: :purchase_process,
    is_default: false,
    lifecycle_status: :active,
    discarded_at: nil
  )
    raise "Cannot create workflow: No company provided." if company.nil?

    Workflow.new(
      company: company,
      name: name,
      description: description,
      code: code || "WF-#{SecureRandom.hex(4).upcase}",
      process_type: process_type,
      is_default: is_default,
      lifecycle_status: lifecycle_status,
      discarded_at: discarded_at
    )
  end

  def self.create(...)
    workflow = new(...)
    workflow.save!
    workflow
  end
end
