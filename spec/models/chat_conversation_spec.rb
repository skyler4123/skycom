require "rails_helper"

RSpec.describe ChatConversation, type: :model do
  let(:members) { create_list(:chat_user, 2) }

  it "exposes members through memberships" do
    conversation = described_class.new(title: "Team")
    members.each { |member| conversation.chat_conversation_memberships.build(chat_user: member) }
    conversation.save!

    expect(conversation.chat_users.map(&:id)).to match_array(members.map(&:id))
  end

  it "rejects a group with fewer than two members" do
    conversation = described_class.new(title: "Lonely")
    conversation.chat_conversation_memberships.build(chat_user: create(:chat_user))

    expect(conversation).not_to be_valid
    expect(conversation.errors[:base]).to be_present
  end
end
