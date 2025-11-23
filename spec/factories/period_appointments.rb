FactoryBot.define do
  factory :period_appointment do
    period { nil }
    appoint_from { nil }
    appoint_to { nil }
    appoint_for { nil }
    appoint_by { nil }
    name { "MyString" }
    description { "MyString" }
    code { "MyString" }
    value { "MyString" }
  end
end
