# frozen_string_literal: true

# Exams::AssignService — bulk-assigns employees to a published exam.
module Exams
  class AssignService
    def self.call(exam:, employee_ids:, assigned_by:)
      new(exam: exam, employee_ids: employee_ids, assigned_by: assigned_by).call
    end

    def initialize(exam:, employee_ids:, assigned_by:)
      @exam = exam
      @employee_ids = employee_ids
      @assigned_by = assigned_by
    end

    def call
      return failure("This exam is not available.") if exam.archived?
      return failure("Publish the exam before assigning employees.") unless exam.published?

      ids = Array(employee_ids).reject(&:blank?).map(&:to_s).uniq
      return failure("Select at least one employee.") if ids.empty?

      employees = exam.company.employees.kept.where(id: ids).to_a
      return failure("No valid employees selected.") if employees.empty?

      assigned_count = 0
      skipped_count = 0

      ActiveRecord::Base.transaction do
        employees.each do |employee|
          if existing_appointment?(employee)
            skipped_count += 1
            next
          end

          exam.employee_exam_appointments.create!(
            company: exam.company,
            employee: employee,
            workflow_status: :assigned,
            attempt_number: next_attempt_number(employee),
            assigned_by_employee: assigned_by
          )
          assigned_count += 1
        end
      end

      Exams::SummaryJob.perform_later(exam.id)
      { success: true, assigned_count: assigned_count, skipped_count: skipped_count }
    rescue ActiveRecord::RecordInvalid => e
      { success: false, errors: e.record.errors.full_messages }
    rescue ActiveRecord::RecordNotUnique
      { success: false, errors: [ "An employee already has an active attempt. Please reload and try again." ] }
    end

    private

    attr_reader :exam, :employee_ids, :assigned_by

    def existing_appointment?(employee)
      exam.employee_exam_appointments
        .where(employee: employee)
        .where.not(workflow_status: :cancelled)
        .exists?
    end

    def next_attempt_number(employee)
      (exam.employee_exam_appointments.where(employee: employee).maximum(:attempt_number) || 0) + 1
    end

    def failure(message)
      { success: false, errors: [ message ] }
    end
  end
end
