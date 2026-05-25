# spec/factories/answers.rb
FactoryBot.define do
  factory :answer do
    association :question

    initialize_with do
      Seed::AnswerService.new(question: question)
    end
  end
end
