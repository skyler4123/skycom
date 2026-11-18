# spec/models/purchase_match_appointment_spec.rb
require "rails_helper"

RSpec.describe PurchaseMatchAppointment, type: :model do
  describe "table" do
    it "uses purchase_match_appointments" do
      expect(described_class.table_name).to eq("purchase_match_appointments")
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:purchase) }
    it { should belong_to(:related_purchase).class_name("Purchase").optional }
    it { should belong_to(:stock_import).optional }
  end

  describe "validations" do
    it { should validate_numericality_of(:matched_quantity).only_integer.is_greater_than_or_equal_to(0) }
    it { should validate_numericality_of(:matched_amount_cents).only_integer.is_greater_than_or_equal_to(0) }
  end

  describe "enums" do
    it { should define_enum_for(:status).with_prefix(true).with_values(unmatched: 0, partial: 1, matched: 2, disputed: 3) }
  end
end
