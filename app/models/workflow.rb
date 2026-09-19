class Workflow < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :process_type, { purchase_process: 0, leave_process: 1 }, prefix: true
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true

  # --- Associations ---
  belongs_to :company
  belongs_to :category
  has_many :workflow_steps, dependent: :destroy
  has_many :workflow_step_logs, dependent: :destroy

  # --- Validations ---
  validates :name, presence: true, uniqueness: { scope: :company_id }, length: { maximum: 255 }
  validate :category_matches_company

  # --- Callbacks ---
  # prepend: true — must run BEFORE the has_many :workflow_steps dependent: :destroy
  # hook (registered at association declaration), or the purchases.workflow_step_id
  # FK breaks during the cascade.
  before_destroy :release_subject_pointers, prepend: true

  private

  def category_matches_company
    return if category.nil? || company_id == category.company_id

    errors.add(:category, "must belong to the same company")
  end

  def release_subject_pointers
    Purchase.where(workflow_step_id: workflow_step_ids).update_all(workflow_step_id: nil)
  end
end
