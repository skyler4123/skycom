FactoryBot.define do
  factory :billing_payment_method do
    name { Faker::Company.name }
    code { "BPM-#{SecureRandom.hex(4).upcase}" }
    business_type { :b2b }
    payment_mode { :qr }
    strategy { :mock_qr_gateway }
    workflow_status { :confirmed }
    lifecycle_status { :active }

    trait :mock_qr do
      name { "Mock QR" }
      code { "QR_BANK_TRANSFER" }
      payment_mode { :qr }
      strategy { :mock_qr_gateway }
    end

    trait :mock_redirect do
      name { "Mock Redirect" }
      code { "REDIRECT_SESSION" }
      payment_mode { :redirect }
      strategy { :mock_redirect_gateway }
    end
  end
end
