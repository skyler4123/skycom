# frozen_string_literal: true

# Notification — Atomic purpose: one company-wide message broadcast to tag
# audiences.
#
# Why it exists: decouples message content from delivery; the same notification
# can target multiple NotificationTags, and each employee sees it through their
# subscriptions instead of a per-employee copy.
# How it works: Notifications::CreateService writes the row plus its tag
# appointments; `subscribed_for(employee, company)` resolves the notifications
# visible to that employee from their subscribed tags. Per-item read state lives
# in EmployeeNotificationRead.
# Main associations: belongs_to :company; has_many
# :notification_tag_appointments, :notification_tags through them, and
# :employee_notification_reads (dependent: :destroy).
class Notification < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :severity, { info: 0, warning: 1, critical: 2 }, prefix: true
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true

  # --- Associations ---
  belongs_to :company
  has_many :notification_tag_appointments, dependent: :destroy
  has_many :notification_tags, through: :notification_tag_appointments
  has_many :employee_notification_reads, dependent: :destroy

  # --- Scopes ---
  scope :subscribed_for, ->(employee, company) {
    tag_ids = employee.subscribed_notification_tag_ids
    return none if tag_ids.empty?

    joins(:notification_tag_appointments)
      .where(company: company)
      .where(notification_tag_appointments: { notification_tag_id: tag_ids })
      .distinct
  }

  # --- Validations ---
  validates :name, presence: true
end
