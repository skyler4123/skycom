require "rails_helper"

RSpec.describe OrderProcessingV1::FinalizeOrderService do
  describe ".call" do
    let(:company) { create(:company) }
    let(:branch) { create(:branch, company: company) }
    let(:product) { create(:product, company: company, branch: branch) }
    let(:customer) { create(:customer, company: company) }
    let(:warehouse) { create(:warehouse, company: company) }
    let!(:stock) do
      category = product.category
      Stock.create!(
        company: company,
        warehouse: warehouse,
        product: product,
        category: category,
        property_mapping: category.default_property_mapping,
        quantity: 10,
        reorder: 0
      )
    end
    let(:order) do
      order_cat = product.category
      order_pm = order_cat.default_property_mapping
      Order.create!(
        company: company,
        branch: branch,
        customer: customer,
        category: order_cat,
        property_mapping: order_pm,
        name: "Test Order",
        business_type: :online,
        currency_code: :usd,
        workflow_status: :paid
      )
    end
    let!(:oa) do
      OrderAppointment.create!(
        company: company,
        order: order,
        appoint_to: product,
        quantity: 2,
        unit_price: 50,
        total_price: 100
      )
    end

    it "creates StockExport records for each item" do
      expect { described_class.call(order: order) }.to change(StockExport, :count).by(1)
      export = StockExport.last
      expect(export.business_type).to eq("sale")
      expect(export.quantity).to eq(2)
    end

    it "links StockExport to the order" do
      described_class.call(order: order)
      export = StockExport.last
      expect(export.appoint_for_type).to eq("Order")
      expect(export.appoint_for_id).to eq(order.id)
    end
  end
end
