# spec/factories/questions.rb
FactoryBot.define do
  factory :question do
    association :company

    initialize_with do
      Seed::QuestionService.new(company: company)
    end
  end
end
