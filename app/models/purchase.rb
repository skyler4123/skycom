# frozen_string_literal: true

# Purchase — Atomic purpose: purchase order header for buying goods/services from
# a supplier into a warehouse.
#
# Why it exists: purchasing is a separate money/stock flow from sales; the
# purchase header carries supplier, destination warehouse, workflow approval, and
# line items, and can produce a StockImport on completion
# (see docs/PURCHASE_WORKFLOW.md).
# How it works: belongs to company, optional branch/supplier/workflow_step,
# warehouse, category, and property mapping. before_validation binds the
# category's workflow; after_create records the submission log. Line items are
# PurchasePurchaseItemAppointment rows; #total_price is always derived.
# Main associations: belongs_to :warehouse, :company, :category,
# :property_mapping (required), :branch, :supplier, :workflow_step (optional);
# has_many :purchase_items through :purchase_purchase_item_appointments;
# has_many :workflow_step_logs (as: :subject), :stock_imports (as: :appoint_from,
# restrict_with_error).
class Purchase < ApplicationRecord
  include CategoryConcern
  include PropertyMappingConcern
  include DynamicSearchConcern
  include TagConcern

  # Transient creation context — the submission WorkflowStepLog is the permanent record.
  attr_accessor :created_by_employee, :skip_workflow

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
  belongs_to :warehouse
  belongs_to :workflow_step, optional: true
  belongs_to :category
  belongs_to :property_mapping

  has_many :purchase_purchase_item_appointments, dependent: :destroy
  has_many :purchase_items, through: :purchase_purchase_item_appointments
  has_many :workflow_step_logs, as: :subject, dependent: :destroy
  has_many :stock_imports, as: :appoint_from, dependent: :restrict_with_error

  # NOTE: must follow the associations — accepts_nested_attributes_for requires
  # its target association to already exist (docs/MODEL_STRUCTURE.md exception).
  accepts_nested_attributes_for :purchase_purchase_item_appointments, allow_destroy: true

  # --- Validations ---
  validates :name, presence: true, uniqueness: { scope: :company_id }, length: { maximum: 255 }
  validates :currency, presence: true
  validates :business_type, presence: true
  validates :warehouse, presence: true

  # --- Callbacks ---
  before_validation :bind_category_workflow, on: :create
  after_create :record_submission_log

  # --- Methods ---
  def total_price
    purchase_purchase_item_appointments.sum(:total_price)
  end

  private

  # Category is the bridge to the Workflow (docs/PURCHASE_WORKFLOW.md): every purchase
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
end
