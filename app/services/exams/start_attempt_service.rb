# frozen_string_literal: true

# Exams::StartAttemptService — starts or resumes one employee exam attempt.
#
# Starts an existing `assigned` row when present; otherwise creates a new attempt
# when the employee still has attempts left. Snapshots every question and option
# so later question-bank edits never change this attempt.
module Exams
  class StartAttemptService
    def self.call(exam:, employee:)
      new(exam: exam, employee: employee).call
    end

    def initialize(exam:, employee:)
      @exam = exam
      @employee = employee
    end

    def call
      return failure("This exam is not available.") unless exam.published?
      return failure("Employee does not belong to this company.") unless employee.company_id == exam.company_id

      active = exam.employee_exam_appointments.find_by(employee: employee, workflow_status: :in_progress)
      if active
        return {
          success: false,
          errors: [ "You already have an attempt in progress." ],
          active_appointment_id: active.id
        }
      end

      pending = exam.employee_exam_appointments.find_by(employee: employee, workflow_status: :submitted)
      if pending
        return {
          success: false,
          errors: [ "Your previous attempt is waiting for review." ],
          submitted_appointment_id: pending.id
        }
      end

      assignment = exam.employee_exam_appointments.find_by(employee: employee, workflow_status: :assigned)
      unless assignment
        return failure("You are not assigned to this exam.") unless assigned_to_exam?
        return failure("You have used all allowed attempts for this exam.") if exam.max_attempts_reached_for?(employee)

        assignment = exam.employee_exam_appointments.new(
          company: exam.company,
          employee: employee,
          workflow_status: :assigned,
          attempt_number: next_attempt_number
        )
      end

      return failure("This exam has no questions.") if exam.exam_question_appointments.empty?

      appointment = nil
      ActiveRecord::Base.transaction do
        assignment.workflow_status = :in_progress
        assignment.started_at = Time.current
        assignment.deadline_at = exam.duration_minutes.present? ? assignment.started_at + exam.duration_minutes.minutes : nil
        assignment.submitted_at = nil
        assignment.graded_at = nil
        assignment.score = nil
        assignment.passed = nil
        assignment.employee_question_appointments.destroy_all
        build_answers(assignment)
        assignment.save!
        appointment = assignment
      end

      Exams::SummaryJob.perform_later(exam.id)
      { success: true, appointment: appointment }
    rescue ActiveRecord::RecordNotUnique
      { success: false, errors: [ "Another attempt was started. Please reload and try again." ] }
    rescue ActiveRecord::RecordInvalid => e
      { success: false, errors: e.record.errors.full_messages }
    end

    private

    attr_reader :exam, :employee

    def assigned_to_exam?
      exam.employee_exam_appointments
        .where(employee: employee)
        .where.not(workflow_status: :cancelled)
        .exists?
    end

    def next_attempt_number
      (exam.employee_exam_appointments.where(employee: employee).maximum(:attempt_number) || 0) + 1
    end

    def build_answers(appointment)
      exam.exam_question_appointments.order(:position).each_with_index do |exam_question, index|
        question = exam_question.question
        options = question.question_options.order(:position).to_a
        option_ids = options.map(&:id)
        option_ids.shuffle! if exam.shuffle_options? && question.shuffleable?

        appointment.employee_question_appointments.build(
          company: exam.company,
          question: question,
          question_type: question.question_type,
          position: index,
          question_snapshot: snapshot_for(question, options),
          option_order: option_ids,
          selected_option_ids: [],
          points_possible: question.points
        )
      end
    end

    def snapshot_for(question, options)
      {
        "name" => question.name,
        "description" => question.description,
        "correct_text" => question.correct_text,
        "options" => options.map do |option|
          {
            "id" => option.id,
            "content" => option.content,
            "position" => option.position,
            "correct" => option.correct
          }
        end
      }
    end

    def failure(message)
      { success: false, errors: [ message ] }
    end
  end
end
