class EmployeeNotificationRead < ApplicationRecord
  # Read receipt — one row per (employee, notification) the employee has read.
  #
  # Why it exists: unread is computed lazily (tag join minus these rows minus
  # the last_read_all_at shortcut); this table is the per-item half.
  # How to use: written idempotently by Notifications::MarkReadService; pruned by
  # Notifications::MarkAllReadService and the nightly prune job.
  # How it works: company_id derives from the employee via SetDefaultCompanyConcern.
  include SetDefaultCompanyConcern

  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true

  # --- Associations ---
  belongs_to :company
  belongs_to :employee
  belongs_to :notification

  # --- Validations ---
  validates :employee_id, uniqueness: { scope: :notification_id }
end
