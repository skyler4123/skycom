# spec/models/purchase_parent_appointment_spec.rb
require "rails_helper"

RSpec.describe PurchaseParentAppointment, type: :model do
  describe "table" do
    it "uses purchase_parent_appointments" do
      expect(described_class.table_name).to eq("purchase_parent_appointments")
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:purchase) }
    it { should belong_to(:related_purchase).class_name("Purchase") }
  end

  describe "validations" do
    it "declares purchase_id uniqueness scoped to related_purchase_id, link_type" do
      validator = described_class.validators_on(:purchase_id).detect { |v| v.is_a?(ActiveRecord::Validations::UniquenessValidator) }
      expect(validator).to be_present
      expect(Array(validator.options[:scope]).map(&:to_s)).to eq(%w[related_purchase_id link_type])
    end
  end

  describe "enums" do
    it { should define_enum_for(:link_type).with_prefix(true).with_values(rfq_response: 0, blanket_call_off: 1) }
  end

describe "parent link" do
  it "refuses a document that is its own parent" do
    id = SecureRandom.uuid
    link = described_class.new(purchase_id: id, related_purchase_id: id)
    link.valid?

    expect(link.errors[:related_purchase]).to include("cannot be the same document")
  end
end
end
