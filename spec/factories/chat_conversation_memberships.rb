# spec/factories/chat_conversation_memberships.rb
FactoryBot.define do
  factory :chat_conversation_membership do
    association :chat_user
    # Default conversation carries its own 2 members (group-only rule), so
    # this membership saves as a third member — never members_count: 0.
    association :chat_conversation
  end
end
