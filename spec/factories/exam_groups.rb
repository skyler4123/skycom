# spec/factories/exam_groups.rb
FactoryBot.define do
  factory :exam_group do
    association :company

    initialize_with do
      Seed::ExamGroupService.new(company: company)
    end
  end
end
