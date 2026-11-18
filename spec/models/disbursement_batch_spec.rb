# spec/models/disbursement_batch_spec.rb
require "rails_helper"

RSpec.describe DisbursementBatch, type: :model do
  describe "table" do
    it "uses disbursement_batches" do
      expect(described_class.table_name).to eq("disbursement_batches")
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:branch).optional }
    it { should belong_to(:stored_file).optional }
    it { should have_many(:payrolls).dependent(:nullify) }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_most(255) }
    it { should validate_presence_of(:payment_on) }
    it { should validate_numericality_of(:total_cents).only_integer }
  end

  describe "enums" do
    it { should define_enum_for(:status).with_prefix(true).with_values(draft: 0, approved: 1, exported: 2, paid: 3, failed: 4) }
  end
end
