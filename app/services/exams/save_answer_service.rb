# frozen_string_literal: true

# Exams::SaveAnswerService — validates and saves one answer during an attempt.
module Exams
  class SaveAnswerService
    def self.call(appointment:, answer_id:, selected_option_ids: nil, text_answer: nil)
      new(
        appointment: appointment,
        answer_id: answer_id,
        selected_option_ids: selected_option_ids,
        text_answer: text_answer
      ).call
    end

    def initialize(appointment:, answer_id:, selected_option_ids: nil, text_answer: nil)
      @appointment = appointment
      @answer_id = answer_id
      @selected_option_ids = selected_option_ids
      @text_answer = text_answer
    end

    def call
      return failure("This attempt is not in progress.") unless appointment.workflow_status_in_progress?
      return failure("Time is up.") if appointment.expired_by_time?

      answer = appointment.employee_question_appointments.find_by(id: answer_id)
      return failure("Answer not found.") unless answer

      if answer.text?
        save_text(answer)
      else
        save_choice(answer)
      end
    end

    private

    attr_reader :appointment, :answer_id, :selected_option_ids, :text_answer

    def save_text(answer)
      answer.update!(selected_option_ids: [], text_answer: text_answer.presence)
      { success: true, answer: answer }
    rescue ActiveRecord::RecordInvalid => e
      { success: false, errors: e.record.errors.full_messages }
    end

    def save_choice(answer)
      ids = Array(selected_option_ids).reject(&:blank?).map(&:to_s).uniq
      return failure("Select only one option.") if ids.size > 1

      valid_ids = answer.snapshot_options.map { |option| option["id"].to_s }
      return failure("Selected option does not belong to this question.") if (ids - valid_ids).any?

      answer.update!(selected_option_ids: ids, text_answer: nil)
      { success: true, answer: answer }
    rescue ActiveRecord::RecordInvalid => e
      { success: false, errors: e.record.errors.full_messages }
    end

    def failure(message)
      { success: false, errors: [ message ] }
    end
  end
end
