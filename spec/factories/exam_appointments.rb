# spec/factories/exam_appointments.rb
FactoryBot.define do
  factory :exam_appointment do
    association :company
    association :exam
    association :appoint_to, factory: :employee

    name { "#{exam.name} Appointment" }
    description { "Exam appointment for #{exam.name}." }
    code { "EXAM-APT-#{SecureRandom.hex(4).upcase}" }
    lifecycle_status { ExamAppointment.lifecycle_statuses.keys.sample }
    workflow_status { ExamAppointment.workflow_statuses.keys.sample }
    business_type { ExamAppointment.business_types.keys.sample }
    discarded_at { nil }

    initialize_with do
      Seed::ExamAppointmentService.new(
        company: company,
        exam: exam,
        appoint_to: appoint_to,
        name: name,
        description: description,
        code: code,
        lifecycle_status: lifecycle_status,
        workflow_status: workflow_status,
        business_type: business_type,
        discarded_at: discarded_at
      )
    end

  end
end
