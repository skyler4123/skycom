class Seed::WorkflowStepService
  def self.new(
    company:,
    workflow:,
    name:,
    description: nil,
    code: nil,
    position:,
    lifecycle_status: :active,
    discarded_at: nil
  )
    raise "Cannot create workflow step: No company or workflow provided." if company.nil? || workflow.nil?

    WorkflowStep.new(
      company: company,
      workflow: workflow,
      name: name,
      description: description,
      code: code || "WF-STP-#{SecureRandom.hex(4).upcase}",
      position: position,
      lifecycle_status: lifecycle_status,
      discarded_at: discarded_at
    )
  end

  def self.create(...)
    workflow_step = new(...)
    workflow_step.save!
    workflow_step
  end
end
