class NotificationConfig < ApplicationRecord
  # Per-employee notification preferences (placeholder in v1 — no delivery effect).
  #
  # Why it exists: owns the mark-all-read shortcut (`last_read_all_at`) and will
  # own delivery toggles (mobile, per-tag mute, Slack-style) when they land.
  # How to use: `NotificationConfig.for_employee!(employee)` — exactly one row
  # per employee, created on demand.
  include SetDefaultCompanyConcern

  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true

  # --- Associations ---
  belongs_to :company
  belongs_to :employee

  # --- Validations ---
  validates :employee_id, uniqueness: { scope: :company_id }

  def self.for_employee!(employee)
    find_or_create_by!(company: employee.company, employee: employee) do |config|
      config.last_read_all_at = employee.created_at
    end
  end
end
