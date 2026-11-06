# frozen_string_literal: true

# ExamQuestionAppointment — Atomic purpose: ordered join row binding one Exam
# and one Question.
#
# Why it exists: exams reuse questions from the company pool and need a stable
# display order; the join is the source of truth for that order.
# How it works: company derives from exam/question; positions are updated by the
# exam form sync.
# Main associations: belongs_to :company, :exam, :question.
class ExamQuestionAppointment < ApplicationRecord
  include SetDefaultCompanyConcern

  # --- Associations ---
  belongs_to :company
  belongs_to :exam
  belongs_to :question

  # --- Validations ---
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :question_id, uniqueness: { scope: :exam_id }
end
