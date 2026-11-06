# spec/factories/employee_question_appointments.rb
FactoryBot.define do
  factory :employee_question_appointment do
    association :employee_exam_appointment
    question { association :question, company: employee_exam_appointment.exam.company }
    question_type { question.question_type }
    position { 0 }
    points_possible { question.points }
    question_snapshot do
      {
        "name" => question.name,
        "description" => question.description,
        "options" => question.question_options.map do |option|
          {
            "id" => option.id,
            "content" => option.content,
            "position" => option.position,
            "correct" => option.correct
          }
        end
      }
    end
    option_order { question.question_options.map(&:id) }
  end
end
