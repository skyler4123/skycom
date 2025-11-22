FactoryBot.define do
  factory :tag_appointment do
    tag { nil }
    appoint_from { nil }
    appoint_to { nil }
    appoint_for { nil }
    appoint_by { nil }
    value { "MyString" }
    description { "MyString" }
  end
end
