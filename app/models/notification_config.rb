# frozen_string_literal: true

# NotificationConfig — Atomic purpose: per-employee notification preferences and
# the mark-all-read shortcut (placeholder in v1 — no delivery effect).
#
# Why it exists: owns `last_read_all_at` for the bulk-read calculation and will
# own delivery toggles (mobile, per-tag mute, Slack-style) when they land.
# How it works: `NotificationConfig.for_employee!(employee)` finds or creates
# exactly one row per employee; company_id derives from the employee via
# SetDefaultCompanyConcern.
# Main associations: belongs_to :company, :employee (required; unique per
# company).
class NotificationConfig < ApplicationRecord
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
    find_by(employee: employee) || begin
      create!(company: employee.company, employee: employee, last_read_all_at: employee.created_at)
    rescue ActiveRecord::RecordNotUnique
      find_by!(employee: employee)
    end
  end
end
