# spec/factories/questions.rb
FactoryBot.define do
  factory :question do
    company { nil }
    name { "MyString" }
    description { "MyString" }
    code { "MyString" }
    status { 1 }
    business_type { 1 }
    discarded_at { "2025-11-23 08:24:10" }

    initialize_with do
      Seed::QuestionService.new(
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
