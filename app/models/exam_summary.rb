# frozen_string_literal: true

# ExamSummary — Atomic purpose: cached aggregate result for one exam.
#
# Why it exists: the exam page needs pass rate, score distribution, and per-question
# performance without running aggregate queries on every render; the summary is
# recomputed by a background job after assignment/attempt changes.
# How it works: one row per exam, upserted by Exams::SummaryService.
# Main associations: belongs_to :company, :exam.
class ExamSummary < ApplicationRecord
  include SetDefaultCompanyConcern

  # --- Associations ---
  belongs_to :company
  belongs_to :exam

  # --- Validations ---
  validates :assigned_count, :started_count, :submitted_count, :graded_count,
    :passed_count, :failed_count, :pending_review_count, :expired_count,
    numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :average_score, :highest_score, :lowest_score, :pass_rate,
    numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true
  validates :exam_id, uniqueness: true
end
