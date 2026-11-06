# frozen_string_literal: true

# Exam — Atomic purpose: one exam definition that employees can be assigned to.
#
# Why it exists: HR training and compliance need a timed, scored assessment with
# a reusable question pool, draft/publish lifecycle, and attempt limits.
# How it works: belongs to a company; questions join through ordered atomic rows;
# employees take attempts through EmployeeExamAppointment; an ExamSummary caches
# aggregate results. There is no category/property schema on the exam itself.
# Main associations: belongs_to :company; has_many :exam_question_appointments,
# :questions through, :employee_exam_appointments, :employees through; has_one
# :exam_summary.
class Exam < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :workflow_status, { draft: 0, published: 1, archived: 2 }, prefix: true, default: :draft
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true

  # --- Associations ---
  belongs_to :company

  has_many :exam_question_appointments, -> { order(:position) }, dependent: :destroy
  has_many :questions, -> { order("exam_question_appointments.position") }, through: :exam_question_appointments
  has_many :employee_exam_appointments, dependent: :destroy
  has_many :employees, through: :employee_exam_appointments
  has_one :exam_summary, dependent: :destroy

  # --- Scopes ---
  scope :published, -> { where(workflow_status: :published) }
  scope :draft, -> { where(workflow_status: :draft) }
  scope :archived, -> { where(workflow_status: :archived) }

  # --- Validations ---
  validates :name, presence: true, uniqueness: { scope: :company_id }, length: { maximum: 255 }
  validates :description, length: { maximum: 5000 }, allow_blank: true
  validates :duration_minutes, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :passing_score, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :max_attempts, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validate :must_have_questions, if: :workflow_status_published?

  def published?
    workflow_status_published?
  end

  def draft?
    workflow_status_draft?
  end

  def archived?
    workflow_status_archived?
  end

  def publish!
    update!(workflow_status: :published, published_at: published_at || Time.current)
  end

  def archive!
    update!(workflow_status: :archived)
  end

  def assignable?
    published?
  end

  def time_limit?
    duration_minutes.present?
  end

  def attempts_used_for(employee)
    employee_exam_appointments
      .where(employee: employee)
      .where.not(workflow_status: :cancelled)
      .count
  end

  def max_attempts_reached_for?(employee)
    return false if max_attempts.nil?

    attempts_used_for(employee) >= max_attempts
  end

  private

  def must_have_questions
    errors.add(:base, "Add at least one question before publishing") if exam_question_appointments.empty?
  end
end
