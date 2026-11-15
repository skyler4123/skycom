FactoryBot.define do
  factory :refund do
    association :company
    branch { association :branch, company: company }
    name { "Refund #{SecureRandom.hex(4)}" }
    refund_type { :cash }
  end
end