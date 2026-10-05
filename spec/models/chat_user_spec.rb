require "rails_helper"

RSpec.describe ChatUser, type: :model do
  let(:user) { create(:user) }

  it "requires a unique user_id bridge to the primary User" do
    described_class.create!(user_id: user.id, display_name: "A", email: "a@example.com")
    duplicate = described_class.new(user_id: user.id, display_name: "B", email: "b@example.com")

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:user_id]).to be_present
  end

  it "syncs a display snapshot from a primary User" do
    chat_user = described_class.sync_from_user!(user)

    expect(chat_user.display_name).to eq(user.name)
    expect(chat_user.email).to eq(user.email)
    expect(chat_user.avatar_url).to eq(user.avatar)
  end

  it "re-syncing the same User updates the snapshot without duplicating" do
    described_class.sync_from_user!(user)
    user.update!(name: "Renamed Person")

    expect { described_class.sync_from_user!(user) }.not_to change(described_class, :count)
    expect(described_class.find_by(user_id: user.id).display_name).to eq("Renamed Person")
  end
end
