# spec/models/purchase_item_spec.rb
require "rails_helper"

RSpec.describe PurchaseItem, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:category) }
    it { should belong_to(:property_mapping) }
    it { should have_many(:purchase_item_appointments).dependent(:destroy) }
    it { should have_many(:purchases).through(:purchase_item_appointments) }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_most(255) }

    it "rejects duplicate names within the same company" do
      company = create(:company)
      create(:purchase_item, company: company, name: "Ballpoint pen")
      expect { create(:purchase_item, company: company, name: "Ballpoint pen") }
        .to raise_error(ActiveRecord::RecordInvalid, /Name has already been taken/)
    end
  end

  describe "purchases association" do
    it "lists purchases that reference the item through appointments" do
      purchase = create(:purchase, name: "Pens restock")
      item = create(:purchase_item, company: purchase.company, name: "Ballpoint pen")
      create(:purchase_item_appointment, purchase: purchase, purchase_item: item)

      expect(item.purchases).to include(purchase)
    end
  end

  it_behaves_like "property_mapping concern", PurchaseItem
end
