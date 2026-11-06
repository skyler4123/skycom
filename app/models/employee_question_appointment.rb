# frozen_string_literal: true

# EmployeeQuestionAppointment — Atomic purpose: one question's answer inside an
# employee exam attempt.
#
# Why it exists: attempts need a stable snapshot of the question and options so
# later edits to the question bank never rewrite history; the row also stores the
# employee's selection/text and the awarded points.
# How it works: created at attempt start with question_snapshot and option_order;
# updated by autosave; graded objectively or manually.
# Main associations: belongs_to :company, :employee_exam_appointment, :question,
# optional grader.
class EmployeeQuestionAppointment < ApplicationRecord
  include SetDefaultCompanyConcern

  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :question_type, { single_choice: 0, true_false: 1, text: 2 }, prefix: true

  # --- Associations ---
  belongs_to :company
  belongs_to :employee_exam_appointment
  belongs_to :question
  belongs_to :graded_by_employee, class_name: "Employee", optional: true

  # --- Validations ---
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :points_possible, numericality: { greater_than_or_equal_to: 0 }
  validates :points_awarded, numericality: { greater_than_or_equal_to: 0 }
  validate :points_awarded_within_possible
  validate :selected_options_in_snapshot

  def single_choice?
    question_type_single_choice?
  end

  def true_false?
    question_type_true_false?
  end

  def text?
    question_type_text?
  end

  def choice?
    single_choice? || true_false?
  end

  def snapshot_options
    Array(question_snapshot["options"])
  end

  def option_order_ids
    Array(option_order)
  end

  def display_options
    option_order_ids.filter_map { |id| snapshot_options.find { |option| option["id"] == id } }
  end

  def correct_option_ids
    snapshot_options.select { |option| option["correct"] }.map { |option| option["id"] }
  end

  def selected_options
    snapshot_options.select { |option| Array(selected_option_ids).include?(option["id"]) }
  end

  def answered?
    Array(selected_option_ids).any? || text_answer.present?
  end

  def grade_objective!
    is_correct = Array(selected_option_ids).sort == correct_option_ids.sort
    update!(correct: is_correct, points_awarded: is_correct ? points_possible : 0, graded_at: Time.current)
  end

  def grade_text!(points)
    awarded = (points.presence || 0).to_d
    update!(points_awarded: awarded, correct: awarded == points_possible, graded_at: Time.current)
  end

  private

  def points_awarded_within_possible
    return if points_awarded.blank? || points_possible.blank?
    return if points_awarded >= 0 && points_awarded <= points_possible

    errors.add(:points_awarded, "must be between 0 and points possible")
  end

  def selected_options_in_snapshot
    ids = Array(selected_option_ids).map(&:to_s)
    valid_ids = snapshot_options.map { |option| option["id"].to_s }
    errors.add(:selected_option_ids, "contains an option outside the question snapshot") if (ids - valid_ids).any?
    errors.add(:selected_option_ids, "must have at most one option") if choice? && ids.size > 1
  end
end
