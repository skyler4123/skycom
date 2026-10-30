# frozen_string_literal: true

# Ticket — Atomic purpose: internal employee support/work ticket with a workflow
# approval chain.
#
# Why it exists: internal issues need an owner, assignee, priority, comments, and
# the same category/workflow approval machinery as purchases
# (see docs/TICKET.md, docs/PURCHASE_WORKFLOW.md).
# How it works: belongs to company/employee and optional assigned_employee,
# category, property_mapping, workflow_step; before_validation binds the
# category's workflow, and after_create records the submission and created log.
# Comments and logs are separate rows.
# Main associations: belongs_to :company, :employee (required),
# :assigned_employee, :category, :property_mapping, :workflow_step (optional);
# has_many :ticket_comments, :ticket_logs, :workflow_step_logs (as: :subject,
# dependent: :destroy).
class Ticket < ApplicationRecord
  include CategoryConcern
  include PropertyMappingConcern

  # Transient creation context — the submission WorkflowStepLog is the permanent record.
  attr_accessor :created_by_employee, :skip_workflow

  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :priority, { low: 0, medium: 1, high: 2, urgent: 3 }, prefix: true, default: :medium
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true

  # --- Associations ---
  belongs_to :company
  belongs_to :employee
  belongs_to :assigned_employee, class_name: "Employee", optional: true
  belongs_to :category
  belongs_to :property_mapping, optional: true
  belongs_to :workflow_step, optional: true

  has_many :ticket_comments, dependent: :destroy
  has_many :ticket_logs, dependent: :destroy
  has_many :workflow_step_logs, as: :subject, dependent: :destroy

  # --- Validations ---
  validates :name, presence: true, length: { maximum: 255 }
  validates :priority, presence: true

  # --- Callbacks ---
  before_validation :bind_category_workflow, on: :create
  after_create :record_submission_log
  after_create :log_created

  private

  # Category is the bridge to the Workflow (docs/PURCHASE_WORKFLOW.md): every ticket
  # in the same category follows that category's workflow. No category workflow → draft.
  def bind_category_workflow
    return if workflow_step.present?
    return unless category.present?

    workflow = skip_workflow ? nil : category.default_workflow
    if workflow.nil? || workflow.workflow_steps.none?
      self.workflow_status = :draft if workflow_status.blank?
      return
    end

    self.workflow_step = workflow.workflow_steps.order(:position).first
    self.workflow_status = :pending if workflow_status.blank?
  end

  def record_submission_log
    return if workflow_step.nil?

    WorkflowStepLog.create!(
      company: company,
      workflow: workflow_step.workflow,
      workflow_step: workflow_step,
      subject: self,
      employee: created_by_employee,
      outcome: :submitted,
      metadata: { "from_step_id" => workflow_step.id }
    )
  end

  def log_created
    TicketLog.record!(ticket: self, action: :created, actor: employee)
  rescue StandardError
    nil
  end
end
