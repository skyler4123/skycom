class Purchase < ApplicationRecord
  include CategoryConcern
  include PropertyMappingConcern
  include DynamicSearchConcern
  include TagConcern

  # Transient creation context — the submission WorkflowStepLog is the permanent record.
  attr_accessor :created_by_employee, :skip_default_workflow

  attribute :permission_resource_name, :string, default: -> { self.name }

  enum :country, COUNTRY_CODES, prefix: true, default: :us
  enum :timezone, TIMEZONES, prefix: true, default: :utc

  # --- Enums ---
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true
  enum :currency, CURRENCIE_CODES, prefix: true, default: :usd
  enum :business_type, { office_supply: 0, equipment: 1, service: 2 }

  # --- Associations ---
  belongs_to :company
  belongs_to :branch, optional: true
  belongs_to :supplier, optional: true
  belongs_to :workflow, optional: true
  belongs_to :current_workflow_step, class_name: "WorkflowStep", optional: true
  belongs_to :category
  belongs_to :property_mapping

  has_many :purchase_item_appointments, as: :appoint_to, dependent: :destroy
  has_many :purchase_items, through: :purchase_item_appointments
  has_many :workflow_step_logs, as: :subject, dependent: :destroy

  # NOTE: must follow the associations — accepts_nested_attributes_for requires
  # its target association to already exist (docs/MODEL_STRUCTURE.md exception).
  accepts_nested_attributes_for :purchase_item_appointments, allow_destroy: true

  # --- Validations ---
  validates :name, presence: true, uniqueness: { scope: :company_id }, length: { maximum: 255 }
  validates :currency, presence: true
  validates :business_type, presence: true

  # --- Callbacks ---
  before_validation :bind_default_workflow, on: :create
  after_create :record_submission_log

  # --- Methods ---
  def total_price
    purchase_item_appointments.sum(:total_price)
  end

  private

  def bind_default_workflow
    return if workflow.present?
    return unless company.present?

    default = skip_default_workflow ? nil : company.workflows.default_for(:purchase_process).first

    if default.nil?
      self.workflow_status = :draft if workflow_status.blank?
      return
    end

    self.workflow = default
    self.current_workflow_step = default.workflow_steps.order(:position).first
    self.workflow_status = :pending if workflow_status.blank?
  end

  def record_submission_log
    return if workflow.nil? || current_workflow_step.nil?

    WorkflowStepLog.create!(
      company: company,
      workflow: workflow,
      workflow_step: current_workflow_step,
      subject: self,
      employee: created_by_employee,
      outcome: :submitted,
      metadata: { "from_step_id" => current_workflow_step.id }
    )
  end
end
