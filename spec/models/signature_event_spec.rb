# spec/models/signature_event_spec.rb
require "rails_helper"

RSpec.describe SignatureEvent, type: :model do
  describe "table" do
    it "uses signature_events" do
      expect(described_class.table_name).to eq("signature_events")
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:signature_request) }
  end

  describe "validations" do
    it { should validate_presence_of(:signer_email) }
    it { should validate_length_of(:signer_email).is_at_most(255) }
  end
end
