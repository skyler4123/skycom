# spec/factories/exam_summaries.rb
FactoryBot.define do
  factory :exam_summary do
    association :exam
  end
end
