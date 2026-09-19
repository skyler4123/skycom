class Seed::WorkflowService
  def self.new(
    company:,
    category:,
    name:,
    description: nil,
    code: nil,
    process_type: :purchase_process,
    lifecycle_status: :active,
    discarded_at: nil
  )
    raise "Cannot create workflow: No company or category provided." if company.nil? || category.nil?

    Workflow.new(
      company: company,
      category: category,
      name: name,
      description: description,
      code: code || "WF-#{SecureRandom.hex(4).upcase}",
      process_type: process_type,
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
