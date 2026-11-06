# spec/factories/question_options.rb
FactoryBot.define do
  factory :question_option do
    association :question
    content { "Option #{SecureRandom.hex(2)}" }
    correct { false }
    position { 0 }
  end
end
