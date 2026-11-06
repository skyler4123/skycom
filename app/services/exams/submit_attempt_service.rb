# frozen_string_literal: true

# Exams::SubmitAttemptService — saves final answers, grades objective questions,
# and moves the attempt to graded or submitted (pending text review).
module Exams
  class SubmitAttemptService
    GRACE_PERIOD = EXAM_SUBMIT_GRACE_SECONDS.seconds

    def self.call(appointment:, answers: [])
      new(appointment: appointment, answers: answers).call
    end

    def initialize(appointment:, answers: [])
      @appointment = appointment
      @answers = answers
    end

    def call
      return failure("This attempt is not in progress.") unless appointment.workflow_status_in_progress?

      if overdue?
        result = Exams::ExpireAttemptService.call(appointment: appointment)
        return result unless result[:success]

        return {
          success: false,
          expired: true,
          appointment: appointment.reload,
          errors: [ "Time is up. The exam was submitted automatically." ]
        }
      end

      error = nil
      ActiveRecord::Base.transaction do
        Array(answers).each do |payload|
          data = payload.respond_to?(:to_unsafe_h) ? payload.to_unsafe_h : payload.to_h
          result = Exams::SaveAnswerService.call(
            appointment: appointment,
            answer_id: data[:id] || data["id"],
            selected_option_ids: data[:selected_option_ids] || data["selected_option_ids"],
            text_answer: data[:text_answer] || data["text_answer"]
          )

          unless result[:success]
            error = result[:errors]
            raise ActiveRecord::Rollback
          end
        end

        next if error

        Exams::AttemptScoring.grade_objective_answers!(appointment)
        Exams::AttemptScoring.update_totals!(appointment)
        appointment.update!(submitted_at: Time.current)

        if Exams::AttemptScoring.text_answers_pending?(appointment)
          appointment.update!(workflow_status: :submitted, score: nil, passed: nil)
        else
          Exams::AttemptScoring.finalize_score!(appointment)
          appointment.update!(workflow_status: :graded, graded_at: Time.current)
        end
      end

      return { success: false, errors: error } if error

      Exams::SummaryJob.perform_later(appointment.exam_id)
      { success: true, appointment: appointment }
    rescue ActiveRecord::RecordInvalid => e
      { success: false, errors: e.record.errors.full_messages }
    end

    private

    attr_reader :appointment, :answers

    def overdue?
      appointment.deadline_at.present? && Time.current > appointment.deadline_at + GRACE_PERIOD
    end

    def failure(message)
      { success: false, errors: [ message ] }
    end
  end
end
