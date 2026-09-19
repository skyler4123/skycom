class Workflow < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :process_type, { purchase_process: 0, leave_process: 1 }, prefix: true
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true

  # --- Associations ---
  belongs_to :company
  has_many :workflow_steps, dependent: :destroy
  has_many :workflow_step_logs, dependent: :destroy
  has_many :purchases, foreign_key: :workflow_id, dependent: :nullify

  # NOTE: must follow the associations — accepts_nested_attributes_for requires
  # its target association to already exist (docs/MODEL_STRUCTURE.md exception).
  accepts_nested_attributes_for :workflow_steps

  # --- Scopes ---
  scope :default_for, ->(process_type) {
    where(process_type: process_type, is_default: true).lifecycle_status_active.order(:created_at)
  }

  # --- Validations ---
  validates :name, presence: true, uniqueness: { scope: :company_id }, length: { maximum: 255 }
  validate :only_one_default_per_process, if: :is_default?

  # --- Callbacks ---
  before_destroy :release_purchase_pointers

  private

  def only_one_default_per_process
    duplicate = Workflow.where(company_id: company_id, process_type: process_type, is_default: true)
      .where.not(id: id).exists?
    return unless duplicate

    errors.add(:is_default, "already has a default workflow for this process")
  end

  def release_purchase_pointers
    Purchase.where(workflow_id: id).update_all(current_workflow_step_id: nil)
  end
end
