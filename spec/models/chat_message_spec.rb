require "rails_helper"

RSpec.describe ChatMessage, type: :model do
  let(:conversation) { create(:chat_conversation) }
  let(:member) { conversation.chat_users.first }

  it "saves a text message from a member" do
    message = described_class.new(chat_conversation: conversation, chat_user: member, body: "Hello team")

    expect(message).to be_valid
  end

  it "rejects a message with neither body nor image" do
    message = described_class.new(chat_conversation: conversation, chat_user: member, body: nil)

    expect(message).not_to be_valid
    expect(message.errors[:body]).to be_present
  end

  it "rejects a sender who is not a conversation member" do
    outsider = create(:chat_user)
    message = described_class.new(chat_conversation: conversation, chat_user: outsider, body: "Intruder")

    expect(message).not_to be_valid
    expect(message.errors[:chat_user]).to be_present
  end

  it "attaches an image message with a processable thumb variant" do
    message = described_class.new(chat_conversation: conversation, chat_user: member, body: nil)
    file = File.open(Dir.glob("./faker/images/randoms/*.*").first)
    message.image_attachments.attach(io: file, filename: "chat-seed", content_type: "image/jpeg")
    message.save!

    expect(message.image_attachments).to be_attached
    expect(message).to be_valid
    expect(message.image_attachments.first.variant(:thumb)).to be_present
  end
end
