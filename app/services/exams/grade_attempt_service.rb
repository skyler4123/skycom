# frozen_string_literal: true

# Exams::GradeAttemptService — applies manager points to text answers and
# finalizes the attempt score/pass state.
module Exams
  class GradeAttemptService
    def self.call(appointment:, grades:, grader:)
      new(appointment: appointment, grades: grades, grader: grader).call
    end

    def initialize(appointment:, grades:, grader:)
      @appointment = appointment
      @grades = grades
      @grader = grader
    end

    def call
      return failure("This attempt is not waiting for review.") unless appointment.workflow_status_submitted?

      text_answers = appointment.employee_question_appointments.select(&:text?)
      return failure("There are no text answers to grade.") if text_answers.empty?

      normalized = normalize(grades)
      values = {}
      errors = []

      text_answers.each do |answer|
        raw = normalized[answer.id.to_s]
        if raw.nil?
          errors << "Grade missing for answer #{answer.id}."
          next
        end

        unless numeric?(raw)
          errors << "Points must be a number for answer #{answer.id}."
          next
        end

        points = raw.to_d
        if points.negative? || points > answer.points_possible
          errors << "Points must be between 0 and #{answer.points_possible.to_i} for answer #{answer.id}."
          next
        end

        values[answer.id] = points
      end

      unknown_ids = normalized.keys - text_answers.map { |answer| answer.id.to_s }
      errors << "Answer not found." if unknown_ids.any?
      return { success: false, errors: errors } if errors.any?

      ActiveRecord::Base.transaction do
        text_answers.each do |answer|
          points = values.fetch(answer.id)
          answer.update!(
            points_awarded: points,
            correct: points == answer.points_possible,
            graded_at: Time.current,
            graded_by_employee: grader
          )
        end

        Exams::AttemptScoring.update_totals!(appointment)
        Exams::AttemptScoring.finalize_score!(appointment)
        appointment.update!(workflow_status: :graded, graded_at: Time.current, graded_by_employee: grader)
      end

      Exams::SummaryJob.perform_later(appointment.exam_id)
      { success: true, appointment: appointment }
    rescue ActiveRecord::RecordInvalid => e
      { success: false, errors: e.record.errors.full_messages }
    end

    private

    attr_reader :appointment, :grades, :grader

    def normalize(raw_grades)
      hash = if raw_grades.respond_to?(:to_unsafe_h)
        raw_grades.to_unsafe_h
      elsif raw_grades.respond_to?(:to_h)
        raw_grades.to_h
      else
        raw_grades || {}
      end

      hash.each_with_object({}) { |(key, value), memo| memo[key.to_s] = value }
    end

    def numeric?(value)
      value.is_a?(Numeric) || value.to_s.match?(/\A-?\d+(\.\d+)?\z/)
    end

    def failure(message)
      { success: false, errors: [ message ] }
    end
  end
end
