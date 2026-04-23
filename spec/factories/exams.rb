# spec/factories/exams.rb
FactoryBot.define do
  factory :exam do
    association :company
    association :exam_group

    name { "Exam #{Faker::Lorem.sentence(word_count: 3)}" }
    description { Faker::Lorem.sentence(word_count: 10) }
    code { "EXAM-#{SecureRandom.hex(4).upcase}" }
    status { Exam.statuses.keys.sample }
    business_type { Exam.business_types.keys.sample }
    discarded_at { nil }

    initialize_with do
      Seed::ExamService.new(
        company: company,
        exam_group: exam_group,
        name: name,
        description: description,
        code: code,
        status: status,
        business_type: business_type,
        discarded_at: discarded_at
      )
    end
  end
end
