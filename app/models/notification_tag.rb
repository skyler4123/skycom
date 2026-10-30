# frozen_string_literal: true

# NotificationTag — Atomic purpose: company-scoped audience tag that employees
# subscribe to for notifications.
#
# Why it exists: notification delivery is tag-based (Owner, All Employees,
# role-paired tags, custom tags), so one notification can target a reusable
# audience without per-employee rows.
# How it works: system tags (OWNER_TAG_NAME / ALL_EMPLOYEES_TAG_NAME) are seeded
# and protected from deletion; employees subscribe through
# EmployeeNotificationTagAppointment, and role changes create the matching
# subscriptions.
# Main associations: belongs_to :company; has_many
# :notification_tag_appointments, :notifications through them, and
# :employee_notification_tag_appointments (dependent: :destroy).
class NotificationTag < ApplicationRecord
  attr_accessor :destroying_paired_for_role

  # Canonical system tag names (single source of truth — see Seed::NotificationTagService::FIXED_TAGS).
  OWNER_TAG_NAME = "Owner".freeze
  ALL_EMPLOYEES_TAG_NAME = "All Employees".freeze

  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true
  enum :business_type, { system: 0, custom: 1 }

  # --- Associations ---
  belongs_to :company
  has_many :notification_tag_appointments, dependent: :destroy
  has_many :notifications, through: :notification_tag_appointments
  has_many :employee_notification_tag_appointments, dependent: :destroy

  # --- Validations ---
  validates :name, presence: true, uniqueness: { scope: :company_id }

  before_destroy :prevent_destroy_if_system

  def destroy_paired_for_role!
    self.destroying_paired_for_role = true
    destroy!
  ensure
    self.destroying_paired_for_role = false
  end

  private

  def prevent_destroy_if_system
    return if destroying_paired_for_role
    return unless system?
    raise ActiveRecord::ReadOnlyRecord, "System notification tags cannot be deleted."
  end
end
