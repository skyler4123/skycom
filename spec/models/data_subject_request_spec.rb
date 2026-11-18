# spec/models/data_subject_request_spec.rb
require "rails_helper"

RSpec.describe DataSubjectRequest, type: :model do
  describe "table" do
    it "uses data_subject_requests" do
      expect(described_class.table_name).to eq("data_subject_requests")
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:customer).optional }
    it { should belong_to(:employee).optional }
    it { should belong_to(:user).optional }
  end

  describe "enums" do
    it { should define_enum_for(:request_type).with_prefix(true).with_values(access: 0, erasure: 1, portability: 2, rectification: 3) }
    it { should define_enum_for(:status).with_prefix(true).with_values(received: 0, in_progress: 1, completed: 2, rejected: 3) }
  end

describe "data subject" do
  it "rejects a request that names two data subjects" do
    request = described_class.new(customer_id: SecureRandom.uuid, employee_id: SecureRandom.uuid)
    request.valid?

    expect(request.errors[:base]).to include("must reference exactly one data subject")
  end
end
end
