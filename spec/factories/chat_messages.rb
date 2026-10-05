# spec/factories/chat_messages.rb
FactoryBot.define do
  factory :chat_message do
    association :chat_conversation, members_count: 2
    chat_user { chat_conversation.chat_users.first }
    body { Faker::Lorem.sentence }
  end
end
