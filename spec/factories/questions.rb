# spec/factories/questions.rb
FactoryBot.define do
  factory :question do
    association :company
    name { "Question #{SecureRandom.hex(4)}" }
    description { Faker::Lorem.sentence }
    question_type { :single_choice }
    points { 1 }

    transient do
      category { nil }
      correct_text { nil }
      options { nil }
    end

    initialize_with do
      Seed::QuestionService.new(
        company: company,
        category: category,
        name: name,
        description: description,
        question_type: question_type,
        points: points,
        correct_text: correct_text,
        options: options
      )
    end

    trait :true_false do
      question_type { :true_false }
    end

    trait :text do
      question_type { :text }
    end
  end
end
