# spec/factories/exam_question_appointments.rb
FactoryBot.define do
  factory :exam_question_appointment do
    association :exam
    question { association :question, company: exam.company }
    position { 0 }
  end
end
