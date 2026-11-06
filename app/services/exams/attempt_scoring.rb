# frozen_string_literal: true

# Exams::AttemptScoring — shared scoring/totals logic for attempt lifecycle services.
module Exams
  module AttemptScoring
    module_function

    def grade_objective_answers!(appointment)
      appointment.employee_question_appointments.reload.each do |answer|
        next if answer.text?

        answer.grade_objective!
      end
    end

    def zero_text_answers!(appointment)
      appointment.employee_question_appointments.reload.each do |answer|
        next unless answer.text?

        answer.update!(points_awarded: 0, correct: false, graded_at: Time.current)
      end
    end

    def update_totals!(appointment)
      answers = appointment.employee_question_appointments.reload
      appointment.update!(
        question_count: answers.size,
        correct_count: answers.count { |answer| answer.correct == true },
        total_points: answers.sum(&:points_possible),
        earned_points: answers.sum(&:points_awarded)
      )
    end

    def finalize_score!(appointment, passed: nil)
      total = appointment.total_points.to_d
      earned = appointment.earned_points.to_d
      score = total.positive? ? (earned / total * 100).round(2) : 0

      appointment.update!(
        score: score,
        passed: passed.nil? ? score >= appointment.exam.passing_score : passed
      )
    end

    def text_answers_pending?(appointment)
      appointment.employee_question_appointments.reload.any?(&:text?)
    end
  end
end
