require "rails_helper"

RSpec.describe "Seed chat services" do
  let!(:users) { create_list(:user, 6) }

  it "mirrors users into ChatUsers without duplicating on re-run" do
    expect { Seed::ChatUserService.mirror_subset!(users: users) }.to change(ChatUser, :count).by(6)
    expect { Seed::ChatUserService.mirror_subset!(users: users) }.not_to change(ChatUser, :count)
  end

  it "creates groups of two to six members" do
    chat_users = Seed::ChatUserService.mirror_subset!(users: users)

    conversations = Seed::ChatConversationService.create_groups!(chat_users: chat_users)

    expect(conversations.size).to eq(6)
    expect(conversations.map { |conversation| conversation.chat_users.count }.uniq.sort).to eq([ 2, 3, 4, 5, 6 ])
  end

  it "populates text, image-only and mixed messages sent by members only" do
    chat_users = Seed::ChatUserService.mirror_subset!(users: users)
    conversation = Seed::ChatConversationService.create_groups!(chat_users: chat_users, plan: [ 3 ]).first

    Seed::ChatMessageService.populate!(conversation: conversation, count: 12, image_every: 4)

    messages = conversation.chat_messages.reload
    expect(messages.size).to eq(12)
    expect(messages.map(&:chat_user_id) - conversation.chat_user_ids).to be_empty
    expect(messages.count { |message| message.body.present? && !message.image_attachments.attached? }).to be >= 1
    expect(messages.count { |message| message.body.blank? && message.image_attachments.attached? }).to be >= 1
    expect(messages.count { |message| message.body.present? && message.image_attachments.attached? }).to be >= 1
  end
end
