# spec/factories/chat_conversations.rb
FactoryBot.define do
  factory :chat_conversation do
    sequence(:title) { |n| "Chat Group #{n}" }

    transient do
      members_count { 2 }
    end

    after(:build) do |conversation, evaluator|
      evaluator.members_count.times do
        conversation.chat_conversation_memberships << build(
          :chat_conversation_membership, chat_conversation: conversation
        )
      end
    end
  end
end
