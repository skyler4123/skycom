require "rails_helper"

RSpec.describe Events::ConflictWarningService do
  let(:company) { create(:company) }
  let(:category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: "events") }
  let(:branch) { create(:branch, company: company) }

  def build_event(start_at:, end_at:)
    create(:event, company: company, branch: branch, category: category,
      start_at: start_at, end_at: end_at, workflow_status: :confirmed)
  end

  describe "without an event config" do
    it "returns no warnings" do
      event = build_event(start_at: 2.hours.from_now, end_at: 3.hours.from_now)

      result = described_class.call(event: event)

      expect(result[:warnings]).to eq([])
    end
  end

  describe "facility overlap" do
    it "warns when another event shares a facility in the same window" do
      create(:event_config, company: company, category: category, warn_on_facility_overlap: true)
      facility = create(:facility, company: company)
      facility2 = create(:facility, company: company)
      other = build_event(start_at: 2.hours.from_now, end_at: 4.hours.from_now)
      EventFacilityAppointment.create!(company: company, event: other, facility: facility)
      event = build_event(start_at: 3.hours.from_now, end_at: 5.hours.from_now)
      EventFacilityAppointment.create!(company: company, event: event, facility: facility)
      EventFacilityAppointment.create!(company: company, event: event, facility: facility2)

      result = described_class.call(event: event)

      expect(result[:warnings].size).to eq(1)
      expect(result[:warnings].first).to include(facility.name)
    end

    it "stays silent when the flag is off" do
      create(:event_config, company: company, category: category, warn_on_facility_overlap: false)
      facility = create(:facility, company: company)
      other = build_event(start_at: 2.hours.from_now, end_at: 4.hours.from_now)
      EventFacilityAppointment.create!(company: company, event: other, facility: facility)
      event = build_event(start_at: 3.hours.from_now, end_at: 5.hours.from_now)
      EventFacilityAppointment.create!(company: company, event: event, facility: facility)

      result = described_class.call(event: event)

      expect(result[:warnings]).to eq([])
    end

    it "ignores cancelled events" do
      create(:event_config, company: company, category: category, warn_on_facility_overlap: true)
      facility = create(:facility, company: company)
      other = build_event(start_at: 2.hours.from_now, end_at: 4.hours.from_now)
      other.update!(workflow_status: :cancelled)
      EventFacilityAppointment.create!(company: company, event: other, facility: facility)
      event = build_event(start_at: 3.hours.from_now, end_at: 5.hours.from_now)
      EventFacilityAppointment.create!(company: company, event: event, facility: facility)

      result = described_class.call(event: event)

      expect(result[:warnings]).to eq([])
    end
  end

  describe "host overlap" do
    it "warns when another event shares an employee in the same window" do
      create(:event_config, company: company, category: category, warn_on_host_overlap: true)
      host = create(:employee, company: company)
      other = build_event(start_at: 2.hours.from_now, end_at: 4.hours.from_now)
      EmployeeEventAppointment.create!(company: company, event: other, employee: host)
      event = build_event(start_at: 3.hours.from_now, end_at: 5.hours.from_now)
      EmployeeEventAppointment.create!(company: company, event: event, employee: host)

      result = described_class.call(event: event)

      expect(result[:warnings].size).to eq(1)
      expect(result[:warnings].first).to include(host.name)
    end

    it "stays silent when the flag is off" do
      create(:event_config, company: company, category: category, warn_on_host_overlap: false)
      host = create(:employee, company: company)
      other = build_event(start_at: 2.hours.from_now, end_at: 4.hours.from_now)
      EmployeeEventAppointment.create!(company: company, event: other, employee: host)
      event = build_event(start_at: 3.hours.from_now, end_at: 5.hours.from_now)
      EmployeeEventAppointment.create!(company: company, event: event, employee: host)

      result = described_class.call(event: event)

      expect(result[:warnings]).to eq([])
    end
  end

  describe "stock shortage" do
    it "warns when a needed stock cannot cover the event" do
      warehouse = create(:warehouse, company: company)
      product = create(:product, company: company)
      stock = Seed::StockService.create(warehouse: warehouse, product_id: product.id, company: company, branch: warehouse.branch)
      stock.update_columns(quantity: 2, pending: 0)
      event = build_event(start_at: 2.hours.from_now, end_at: 3.hours.from_now)
      EventStockAppointment.create!(company: company, event: event, stock: stock, quantity: 5)

      result = described_class.call(event: event)

      expect(result[:warnings].size).to eq(1)
      expect(result[:warnings].first).to include(stock.name)
    end
  end
end
