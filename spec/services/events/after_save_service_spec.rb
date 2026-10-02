require "rails_helper"

RSpec.describe Events::AfterSaveService do
  let(:company) { create(:company) }
  let(:category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: "events") }
  let(:branch) { create(:branch, company: company) }
  let(:event) do
    create(:event, company: company, branch: branch, category: category,
      start_at: 2.hours.from_now, end_at: 3.hours.from_now, workflow_status: :confirmed)
  end

  def stock_with_units(units)
    warehouse = create(:warehouse, company: company)
    product = create(:product, company: company)
    stock = Seed::StockService.create(warehouse: warehouse, product_id: product.id, company: company, branch: warehouse.branch)
    stock.update_columns(quantity: units, pending: 0)
    stock.available_counter.increment(by: units)
    stock
  end

  describe "holds" do
    it "creates event holds when the category opts in" do
      create(:event_config, company: company, category: category, create_stock_pending: true)
      stock = stock_with_units(10)
      EventStockAppointment.create!(company: company, event: event, stock: stock, quantity: 3)

      result = described_class.call(event: event.reload)

      expect(result[:warnings]).to eq([])
      expect(stock.reload.pending).to eq(3)
      expect(StockPending.where(company: company, stock: stock, business_type: :event).count).to eq(1)
    end

    it "creates nothing when the category opts out" do
      create(:event_config, company: company, category: category, create_stock_pending: false)
      stock = stock_with_units(10)
      EventStockAppointment.create!(company: company, event: event, stock: stock, quantity: 3)

      result = described_class.call(event: event.reload)

      expect(result[:warnings]).to eq([])
      expect(stock.reload.pending).to eq(0)
      expect(StockPending.where(company: company, stock: stock).count).to eq(0)
    end

    it "warns but keeps the event when a hold fails and strict is off" do
      create(:event_config, company: company, category: category,
        create_stock_pending: true, strict_stock_hold: false)
      stock = stock_with_units(1)
      EventStockAppointment.create!(company: company, event: event, stock: stock, quantity: 5)

      result = described_class.call(event: event.reload)

      expect(result[:warnings].any? { |w| w.include?("Could not hold") }).to be(true)
      expect(stock.reload.pending).to eq(0)
    end

    it "raises when a hold fails and strict is on" do
      create(:event_config, company: company, category: category,
        create_stock_pending: true, strict_stock_hold: true)
      stock = stock_with_units(1)
      EventStockAppointment.create!(company: company, event: event, stock: stock, quantity: 5)

      expect do
        described_class.call(event: event.reload)
      end.to raise_error(Events::StrictHoldError)
    end
  end

  describe "update reconciliation" do
    it "releases holds for removed lines" do
      create(:event_config, company: company, category: category, create_stock_pending: true)
      stock = stock_with_units(10)
      line = EventStockAppointment.create!(company: company, event: event, stock: stock, quantity: 3)
      described_class.call(event: event.reload)
      expect(stock.reload.pending).to eq(3)

      previous_map = { stock.id => 3 }
      line.destroy!

      described_class.call(event: event.reload, previous_stock_map: previous_map)

      expect(stock.reload.pending).to eq(0)
    end
  end

  describe "done transition" do
    it "releases holds on completed and builds the order when asked" do
      create(:event_config, company: company, category: category,
        create_stock_pending: true, create_order_on_complete: true)
      stock = stock_with_units(10)
      EventStockAppointment.create!(company: company, event: event, stock: stock, quantity: 3)
      described_class.call(event: event.reload)
      expect(stock.reload.pending).to eq(3)

      event.update!(workflow_status: :completed)
      result = described_class.call(event: event.reload, previous_workflow_status: "confirmed")

      expect(result[:warnings]).to eq([])
      expect(stock.reload.pending).to eq(0)
      expect(EventOrderAppointment.where(event: event).count).to eq(1)
    end

    it "releases holds on cancelled without building an order" do
      create(:event_config, company: company, category: category,
        create_stock_pending: true, create_order_on_complete: true)
      stock = stock_with_units(10)
      EventStockAppointment.create!(company: company, event: event, stock: stock, quantity: 3)
      described_class.call(event: event.reload)

      event.update!(workflow_status: :cancelled)
      result = described_class.call(event: event.reload, previous_workflow_status: "confirmed")

      expect(stock.reload.pending).to eq(0)
      expect(EventOrderAppointment.where(event: event).count).to eq(0)
    end

    it "does nothing extra when the status did not reach done" do
      create(:event_config, company: company, category: category,
        create_stock_pending: true, create_order_on_complete: true)
      stock = stock_with_units(10)
      EventStockAppointment.create!(company: company, event: event, stock: stock, quantity: 3)
      described_class.call(event: event.reload)

      event.update!(workflow_status: :in_progress)
      result = described_class.call(event: event.reload,
        previous_workflow_status: "confirmed", previous_stock_map: { stock.id => 3 })

      expect(stock.reload.pending).to eq(3)
      expect(EventOrderAppointment.where(event: event).count).to eq(0)
      expect(result[:warnings]).to eq([])
    end
  end
end
