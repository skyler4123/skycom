# frozen_string_literal: true

module Exams
  class SummaryJob < ApplicationJob
    queue_as :default

    def perform(exam_id)
      exam = Exam.find_by(id: exam_id)
      return unless exam

      Exams::SummaryService.call(exam: exam)
    end
  end
end
