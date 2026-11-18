# spec/models/signature_request_spec.rb
require "rails_helper"

RSpec.describe SignatureRequest, type: :model do
  describe "table" do
    it "uses signature_requests" do
      expect(described_class.table_name).to eq("signature_requests")
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:document).optional }
    it { should belong_to(:stored_file).optional }
    it { should belong_to(:requested_by_employee).class_name("Employee").optional }
    it { should have_many(:signature_events).dependent(:destroy) }
  end

  describe "enums" do
    it { should define_enum_for(:status).with_prefix(true).with_values(pending: 0, completed: 1, declined: 2, expired: 3, canceled: 4) }
  end

describe "subject" do
  it "rejects a request with two subjects" do
    request = described_class.new(document_id: SecureRandom.uuid, stored_file_id: SecureRandom.uuid)
    request.valid?

    expect(request.errors[:base]).to include("must reference exactly one document or stored file")
  end

  it "accepts a request with one subject" do
    request = described_class.new(document_id: SecureRandom.uuid)
    request.valid?

    expect(request.errors[:base]).to eq([])
  end
end
end
