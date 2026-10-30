# frozen_string_literal: true

# EmployeeNotificationRead — Atomic purpose: per-employee read receipt for one
# Notification.
#
# Why it exists: unread is computed lazily (tag subscription join minus these
# rows minus the `last_read_all_at` shortcut); this table is the per-item half.
# How it works: written idempotently by Notifications::MarkReadService and pruned
# by Notifications::MarkAllReadService and the nightly prune job; company_id
# derives from the employee via SetDefaultCompanyConcern.
# Main associations: belongs_to :company, :employee, :notification (required);
# employee + notification is unique.
class EmployeeNotificationRead < ApplicationRecord
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
