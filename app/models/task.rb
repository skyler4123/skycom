class Task < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  include TagConcern

  # --- Associations ---
  belongs_to :company
  belongs_to :branch, optional: true
  belongs_to :task_group

  # --- Enums ---
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true

  enum :business_type, {
    general: 0,
    technical: 1,
    administrative: 2
  }

  enum :currency_code, {
    usd: 0,
    eur: 1,
    gbp: 2
  }

  # --- Validations ---
  validates :name, presence: true, length: { maximum: 255 }

  validates :business_type, presence: true
end
