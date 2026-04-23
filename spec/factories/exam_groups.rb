# spec/factories/exam_groups.rb
FactoryBot.define do
  factory :exam_group do
    association :company

    name { "ExamGroup #{Faker::Lorem.sentence(word_count: 3)}" }
    description { Faker::Lorem.sentence(word_count: 10) }
    code { "EXAMG-#{SecureRandom.hex(4).upcase}" }
    status { ExamGroup.statuses.keys.sample }
    business_type { ExamGroup.business_types.keys.sample }
    discarded_at { nil }

    initialize_with do
      Seed::ExamGroupService.new(
        company: company,
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
