# spec/support/exam_helpers.rb
module ExamHelpers
  def publish_exam!(exam)
    exam.publish! unless exam.published?
    exam
  end

  def assign_exam!(exam, employee)
    create(:employee_exam_appointment, exam: exam, employee: employee, workflow_status: :assigned)
  end

  def start_exam!(exam, employee)
    publish_exam!(exam)
    assignment = exam.employee_exam_appointments.find_by(employee: employee, workflow_status: :assigned)
    assignment ||= assign_exam!(exam, employee)
    result = Exams::StartAttemptService.call(exam: exam, employee: employee)
    raise result[:errors].join(", ") unless result[:success]

    result[:appointment]
  end
end

RSpec.configure do |config|
  config.include ExamHelpers
end
