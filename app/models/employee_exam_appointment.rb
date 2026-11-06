# frozen_string_literal: true

# EmployeeExamAppointment — Atomic purpose: one employee attempt at one exam.
#
# Why it exists: an employee may be assigned to an exam and may take it more than
# once when the exam allows; each attempt carries its own timer, score, pass/fail,
# and answer rows. The row is the assignment until the employee starts it.
# How it works: status moves assigned → in_progress → submitted → graded, or to
# expired when the deadline passes. At most one active attempt per employee/exam
# is enforced by a partial unique index and a model validation.
# Main associations: belongs_to :company, :employee, :exam, optional assigner and
# grader; has_many :employee_question_appointments.
class EmployeeExamAppointment < ApplicationRecord
  include SetDefaultCompanyConcern

  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :workflow_status, {
    assigned: 0,
    in_progress: 1,
    submitted: 2,
    graded: 3,
    expired: 4,
    cancelled: 5
  }, prefix: true, default: :assigned
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true

  # --- Associations ---
  belongs_to :company
  belongs_to :employee
  belongs_to :exam
  belongs_to :assigned_by_employee, class_name: "Employee", optional: true
  belongs_to :graded_by_employee, class_name: "Employee", optional: true

  has_many :employee_question_appointments, dependent: :destroy
  has_many :questions, through: :employee_question_appointments

  # --- Scopes ---
  scope :active, -> { where(workflow_status: [ :assigned, :in_progress ]) }
  scope :completed, -> { where(workflow_status: [ :graded, :expired ]) }
  scope :pending_review, -> { where(workflow_status: :submitted) }
  scope :passed, -> { where(workflow_status: :graded, passed: true) }
  scope :failed, -> { where(workflow_status: :graded, passed: false) }

  # --- Validations ---
  validates :attempt_number, numericality: { only_integer: true, greater_than: 0 }
  validates :attempt_number, uniqueness: { scope: [ :company_id, :employee_id, :exam_id ] }
  validates :score, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true
  validate :single_active_attempt

  def active?
    workflow_status_assigned? || workflow_status_in_progress?
  end

  def completed?
    workflow_status_graded? || workflow_status_expired?
  end

  def pending_review?
    workflow_status_submitted?
  end

  def gradeable?
    pending_review?
  end

  def can_retake?
    return false if active?
    return false unless completed?

    !exam.max_attempts_reached_for?(employee)
  end

  def time_remaining_seconds
    return nil if deadline_at.blank?

    [ (deadline_at - Time.current).to_i, 0 ].max
  end

  def expired_by_time?
    workflow_status_in_progress? && deadline_at.present? && deadline_at < Time.current
  end

  private

  def single_active_attempt
    return unless active?

    scope = self.class.where(company_id: company_id, employee_id: employee_id, exam_id: exam_id).active
    scope = scope.where.not(id: id) if persisted?
    errors.add(:base, "An active attempt already exists") if scope.exists?
  end
end
