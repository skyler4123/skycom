# frozen_string_literal: true

# Notification — Atomic purpose: one company-scoped message delivered to a tag
# audience or one directly addressed employee.
#
# Why it exists: decouples message content from delivery; the same notification
# can target multiple NotificationTags, while operational alerts (reception host,
# parcel recipient) need exactly one inbox without broadcasting to everyone.
# How it works: Notifications::CreateService writes the row, its tag
# appointments, and/or `recipient_employee_id`; `subscribed_for(employee,
# company)` resolves tag-visible plus directly addressed notifications. Per-item
# read state lives in EmployeeNotificationRead.
# Main associations: belongs_to :company, :recipient_employee (optional);
# has_many :notification_tag_appointments, :notification_tags through them, and
# :employee_notification_reads (dependent: :destroy).
class Notification < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :severity, { info: 0, warning: 1, critical: 2 }, prefix: true
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true

  # --- Associations ---
  belongs_to :company
  belongs_to :recipient_employee, class_name: "Employee", optional: true
  has_many :notification_tag_appointments, dependent: :destroy
  has_many :notification_tags, through: :notification_tag_appointments
  has_many :employee_notification_reads, dependent: :destroy

  # --- Scopes ---
  scope :subscribed_for, ->(employee, company) {
    base = where(company: company)
    direct = base.where(recipient_employee_id: employee.id)
    tag_ids = employee.subscribed_notification_tag_ids
    return direct if tag_ids.empty?

    tagged_ids = NotificationTagAppointment
      .where(notification_tag_id: tag_ids)
      .select(:notification_id)
    base.where(id: tagged_ids).or(direct)
  }

  # --- Validations ---
  validates :name, presence: true
end
