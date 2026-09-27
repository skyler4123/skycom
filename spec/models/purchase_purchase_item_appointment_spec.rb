require "rails_helper"

RSpec.describe PurchasePurchaseItemAppointment, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:purchase) }
    it { should belong_to(:purchase_item) }
  end

  describe "validations" do
    it { should validate_numericality_of(:quantity).only_integer.is_greater_than_or_equal_to(0).allow_nil }
    it { should validate_numericality_of(:unit_price).is_greater_than_or_equal_to(0).allow_nil }
    it { should validate_numericality_of(:total_price).is_greater_than_or_equal_to(0).allow_nil }
  end

  describe "derives company from the purchase" do
    it "sets company_id when not given" do
      purchase = create(:purchase, name: "Pens restock")
      item = create(:purchase_item, company: purchase.company, name: "Ballpoint pen")

      appointment = described_class.create!(purchase: purchase, purchase_item: item, quantity: 10, unit_price: 2.0)

      expect(appointment.company_id).to eq(purchase.company_id)
    end
  end

  describe "purchase aggregation" do
    it "is reachable from the purchase" do
      purchase = create(:purchase, name: "Pens restock")
      item = create(:purchase_item, company: purchase.company, name: "Ballpoint pen")
      appointment = create(:purchase_purchase_item_appointment, purchase: purchase, purchase_item: item)

      expect(purchase.purchase_purchase_item_appointments).to include(appointment)
      expect(purchase.purchase_items).to include(item)
    end
  end
end
