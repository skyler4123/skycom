# frozen_string_literal: true

# CourseEnrollment — Atomic purpose: one employee's progress and certification status for one course.
#
# Why it exists: completion and expiry are per employee: a certificate that is valid today must expire next year, and a mandatory course needs to show who is overdue. Storing it on the course would make every employee share one status.
# How it works: one row per (course, employee). `expires_on` drives re-certification reminders; `exam` links the assessment that must be passed. Status tracks enrolled → in_progress → completed → expired.
# Main associations: belongs_to :company, :course, :employee, :exam (optional).
class CourseEnrollment < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :status, ENROLLMENT_STATUSES, prefix: true, default: :enrolled

  # --- Associations ---
  belongs_to :company
  belongs_to :course
  belongs_to :employee
  belongs_to :exam, optional: true

  # --- Scopes ---
  scope :completed, -> { where(status: :completed) }
  scope :expiring_before, ->(date) { where.not(expires_on: nil).where(expires_on: ..date) }

  # --- Validations ---
  validates :employee_id, uniqueness: { scope: :course_id }
  validates :progress_percent, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }

  # --- Methods ---
  def expired?
    expires_on.present? && expires_on < Date.current
  end
end
