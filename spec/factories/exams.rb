# spec/factories/exams.rb
FactoryBot.define do
  factory :exam do
    association :company
    association :exam_group

    initialize_with do
      Seed::ExamService.new(company: company, exam_group: exam_group)
    end
  end
end
