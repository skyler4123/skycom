require "rails_helper"

RSpec.describe ChatConversationMembership, type: :model do
  it "rejects a duplicate member in the same conversation" do
    membership = create(:chat_conversation_membership)
    duplicate = described_class.new(
      chat_conversation: membership.chat_conversation,
      chat_user: membership.chat_user
    )

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:chat_user_id]).to be_present
  end
end
