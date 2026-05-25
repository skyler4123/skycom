# spec/factories/exam_appointments.rb
FactoryBot.define do
  factory :exam_appointment do
    association :company
    association :exam
    association :appoint_to, factory: :employee

    initialize_with do
      Seed::ExamAppointmentService.new(company: company, exam: exam, appoint_to: appoint_to)
    end
  end
end
