# spec/factories/exams.rb
FactoryBot.define do
  factory :exam do
    association :company
    name { "Exam #{SecureRandom.hex(4)}" }
    description { Faker::Lorem.sentence }
    duration_minutes { 30 }
    passing_score { 70 }
    max_attempts { 1 }
    shuffle_options { true }

    transient do
      questions_count { 1 }
    end

    initialize_with do
      questions = Array.new(questions_count) { build(:question, company: company) }
      Seed::ExamService.new(
        company: company,
        name: name,
        description: description,
        duration_minutes: duration_minutes,
        passing_score: passing_score,
        max_attempts: max_attempts,
        shuffle_options: shuffle_options,
        questions: questions
      )
    end

    trait :published do
      workflow_status { :published }
      published_at { Time.current }
    end
  end
end
