# spec/factories/chat_users.rb
FactoryBot.define do
  factory :chat_user do
    user_id { SecureRandom.uuid }
    sequence(:display_name) { |n| "Chat User #{n}" }
    sequence(:email) { |n| "chat-user-#{n}@example.com" }
    avatar_url { nil }
  end
end
