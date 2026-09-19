# spec/models/purchase_item_appointment_spec.rb
require "rails_helper"

RSpec.describe PurchaseItemAppointment, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:purchase_item) }
    it { should belong_to(:appoint_to) }
    it { should belong_to(:appoint_from).optional }
    it { should belong_to(:appoint_for).optional }
    it { should belong_to(:appoint_by).optional }
  end

  describe "validations" do
    it { should validate_numericality_of(:quantity).only_integer.is_greater_than_or_equal_to(0).allow_nil }
    it { should validate_numericality_of(:unit_price).is_greater_than_or_equal_to(0).allow_nil }
    it { should validate_numericality_of(:total_price).is_greater_than_or_equal_to(0).allow_nil }

    it "derives company from the purchase item" do
      purchase = create(:purchase, name: "Pens restock")
      item = create(:purchase_item, company: purchase.company, name: "Ballpoint pen")

      appointment = described_class.create!(purchase_item: item, appoint_to: purchase, quantity: 10, unit_price: 2.0)

      expect(appointment.company_id).to eq(purchase.company_id)
    end

    it "rejects an appoint_to from another company" do
      purchase = create(:purchase, name: "Pens restock")
      item = create(:purchase_item, name: "Ballpoint pen") # different company

      expect {
        described_class.create!(purchase_item: item, appoint_to: purchase, quantity: 10, unit_price: 2.0)
      }.to raise_error(ActiveRecord::RecordInvalid, /same company/)
    end
  end

  describe "purchase aggregation" do
    it "is reachable from the purchase as appoint_to" do
      purchase = create(:purchase, name: "Pens restock")
      item = create(:purchase_item, company: purchase.company, name: "Ballpoint pen")
      appointment = create(:purchase_item_appointment, purchase: purchase, purchase_item: item)

      expect(purchase.purchase_item_appointments).to include(appointment)
      expect(purchase.purchase_items).to include(item)
    end
  end
end
