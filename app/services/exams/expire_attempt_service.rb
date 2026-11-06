# frozen_string_literal: true

# Exams::ExpireAttemptService — closes an overdue in-progress attempt.
module Exams
  class ExpireAttemptService
    def self.call(appointment:)
      new(appointment: appointment).call
    end

    def initialize(appointment:)
      @appointment = appointment
    end

    def call
      return failure("This attempt is not overdue.") unless appointment.expired_by_time?

      ActiveRecord::Base.transaction do
        Exams::AttemptScoring.grade_objective_answers!(appointment)
        Exams::AttemptScoring.zero_text_answers!(appointment)
        Exams::AttemptScoring.update_totals!(appointment)
        Exams::AttemptScoring.finalize_score!(appointment, passed: false)
        appointment.update!(
          workflow_status: :expired,
          submitted_at: appointment.submitted_at || appointment.deadline_at || Time.current,
          graded_at: Time.current
        )
      end

      Exams::SummaryJob.perform_later(appointment.exam_id)
      { success: true, appointment: appointment }
    rescue ActiveRecord::RecordInvalid => e
      { success: false, errors: e.record.errors.full_messages }
    end

    private

    attr_reader :appointment

    def failure(message)
      { success: false, errors: [ message ] }
    end
  end
end
