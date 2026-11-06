# frozen_string_literal: true

module Exams
  class ExpireAttemptsJob < ApplicationJob
    queue_as :default

    def perform
      EmployeeExamAppointment
        .where(workflow_status: :in_progress)
        .where("deadline_at < ?", Time.current)
        .find_each do |appointment|
          Exams::ExpireAttemptService.call(appointment: appointment)
        rescue StandardError => e
          Rails.logger.warn("[Exams::ExpireAttemptsJob] appointment #{appointment.id}: #{e.message}")
        end
    end
  end
end
