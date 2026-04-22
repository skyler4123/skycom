# spec/factories/answers.rb
FactoryBot.define do
  factory :answer do
    question { nil }
    content { "MyString" }
    description { "MyString" }
    status { 1 }
    discarded_at { "2025-11-23 08:24:11" }

    initialize_with do
      Seed::AnswerService.create(
        question: question,
        content: content,
        description: description,
        status: status,
        discarded_at: discarded_at
      )
    end

    skip_create
  end
end
