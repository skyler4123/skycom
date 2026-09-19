class WorkflowStep < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true

  # --- Associations ---
  belongs_to :company
  belongs_to :workflow

  has_many :workflow_step_logs, dependent: :destroy

  # --- Validations ---
  validates :name, presence: true, length: { maximum: 255 }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 1 },
    uniqueness: { scope: :workflow_id }

  # --- Methods ---
  def next_step
    workflow.workflow_steps.where("position > ?", position).order(:position).first
  end

  def previous_step
    workflow.workflow_steps.where("position < ?", position).order(:position).last
  end
end
