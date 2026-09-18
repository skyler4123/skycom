# frozen_string_literal: true

# == Purpose:
# Advance a subject (e.g. Purchase) through its bound Workflow. This is the
# single write path for workflow state: one transaction that authorizes the
# acting employee, records a WorkflowStepLog (the transition + audit record),
# moves the subject's current_workflow_step pointer, and syncs the subject's
# workflow_status.
#
# == Permission (single system — ABAC):
# Transitions are Jira-style: anyone who holds update permission on the
# subject may advance it — `employee.can?(:update, subject)` is the only
# authorization check. There is NO per-step role mechanism; WorkflowStepLog
# is the permanent audit of who did what.
#
# Subjects must respond to:
#   - current_workflow_step  (WorkflowStep or nil)
#   - workflow               (Workflow or nil)
#   - workflow_status=       (enum assignment)
#   - company
#   - can? — the subject's class must be ABAC-checkable (instance-level tags)
#
# Returns a result object — never raises for business failures:
#   { success: true } | { success: false, errors: ["..."] }
class Workflows::AdvanceService
  ALLOWED_OUTCOMES = %w[approved rejected rework].freeze

  def self.call(subject:, employee:, outcome:, note: nil, target_step: nil)
    new(subject: subject, employee: employee, outcome: outcome, note: note, target_step: target_step).call
  end

  def initialize(subject:, employee:, outcome:, note: nil, target_step: nil)
    @subject = subject
    @employee = employee
    @outcome = outcome.to_s
    @note = note
    @target_step = target_step
  end

  def call
    return failure("Subject has no active workflow") if current_step.nil?
    return failure("Employee is required") if @employee.nil?
    return failure("Invalid outcome") unless ALLOWED_OUTCOMES.include?(@outcome)
    return failure("Workflow already completed") if @subject.workflow_status.to_s == "completed"
    return failure("Workflow was cancelled") if @subject.workflow_status.to_s == "cancelled"
    return failure("You are not authorized to update this record") unless @employee.can?(:update, @subject)
    return failure("Rework target step is required") if @outcome == "rework" && @target_step.nil?
    return failure("Rework target must belong to the same workflow") if @target_step && @target_step.workflow_id != current_step.workflow_id

    ActiveRecord::Base.transaction do
      write_log!
      apply_transition!
    end

    { success: true }
  end

  private

  def current_step
    @current_step ||= @subject.current_workflow_step
  end

  def write_log!
    WorkflowStepLog.create!(
      company: @subject.company,
      workflow: current_step.workflow,
      workflow_step: current_step,
      subject: @subject,
      employee: @employee,
      outcome: @outcome,
      note: @note,
      metadata: log_metadata
    )
  end

  def log_metadata
    { "from_step_id" => current_step.id, "target_step_id" => @target_step&.id }.compact
  end

  def apply_transition!
    case @outcome
    when "approved"
      next_step = current_step.next_step
      if next_step
        @subject.update!(current_workflow_step: next_step, workflow_status: :confirmed)
      else
        @subject.update!(workflow_status: :completed)
      end
    when "rejected"
      @subject.update!(workflow_status: :cancelled)
    when "rework"
      @subject.update!(current_workflow_step: @target_step, workflow_status: :pending)
    end
  end

  def failure(message)
    { success: false, errors: [ message ] }
  end
end
