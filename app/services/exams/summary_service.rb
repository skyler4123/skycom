# frozen_string_literal: true

# Exams::SummaryService — recomputes and upserts the aggregate ExamSummary.
#
# Counts are per employee (not per attempt): an employee who failed then passed
# counts once in passed and zero in failed; the best graded score is used for
# the score distribution.
module Exams
  class SummaryService
    def self.call(exam:)
      new(exam: exam).call
    end

    def initialize(exam:)
      @exam = exam
    end

    def call
      appointments = exam.employee_exam_appointments
        .where.not(workflow_status: :cancelled)
        .includes(:employee_question_appointments)
        .to_a

      groups = appointments.group_by(&:employee_id)
      graded_groups = groups.select { |_, rows| rows.any? { |row| row.workflow_status_graded? } }
      passed_groups = graded_groups.select { |_, rows| rows.any? { |row| row.workflow_status_graded? && row.passed == true } }
      best_scores = graded_groups.values.map { |rows| rows.select { |row| row.workflow_status_graded? }.map(&:score).compact.max }.compact

      summary = exam.exam_summary || exam.build_exam_summary
      summary.company = exam.company
      summary.assign_attributes(
        assigned_count: groups.size,
        started_count: groups.count { |_, rows| rows.any? { |row| row.started_at.present? } },
        submitted_count: groups.count { |_, rows| rows.any? { |row| row.submitted_at.present? } },
        graded_count: graded_groups.size,
        passed_count: passed_groups.size,
        failed_count: graded_groups.size - passed_groups.size,
        pending_review_count: appointments.count { |row| row.workflow_status_submitted? },
        expired_count: appointments.count { |row| row.workflow_status_expired? },
        average_score: average(best_scores),
        highest_score: best_scores.max,
        lowest_score: best_scores.min,
        pass_rate: pass_rate(passed_groups.size, graded_groups.size),
        question_stats: question_stats,
        computed_at: Time.current
      )
      summary.save!
      summary
    end

    private

    attr_reader :exam

    def average(scores)
      return nil if scores.empty?

      (scores.sum / scores.size).round(2)
    end

    def pass_rate(passed_count, graded_count)
      return nil if graded_count.zero?

      (passed_count.to_f / graded_count * 100).round(2)
    end

    def question_stats
      scope = EmployeeQuestionAppointment
        .joins(:employee_exam_appointment)
        .where(employee_exam_appointments: {
          exam_id: exam.id,
          workflow_status: EmployeeExamAppointment.workflow_statuses[:graded]
        })

      counts = scope.group(:question_id).count
      correct_counts = scope.where(correct: true).group(:question_id).count

      counts.each_with_object({}) do |(question_id, answered_count), result|
        correct_count = correct_counts.fetch(question_id, 0)
        result[question_id] = {
          "answered_count" => answered_count,
          "correct_count" => correct_count,
          "correct_rate" => answered_count.zero? ? nil : (correct_count.to_f / answered_count * 100).round(2)
        }
      end
    end
  end
end
