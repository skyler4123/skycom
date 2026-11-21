# frozen_string_literal: true

require "rails_helper"

RSpec.describe StoreManager::ShiftCloseService, type: :service do
  let(:company) { create(:company) }
  let(:branch) { create(:branch, company: company, timezone: :utc) }
  let(:employee) { create(:employee, company: company, branch: branch, name: "Lekisha Dare") }

  it "stores the cash figures and the same variance on reload" do
    travel_to Time.utc(2026, 11, 20, 17, 0, 0) do
      order, = create_store_invoice_order(
        company: company, branch: branch, employee: employee,
        total_cents: 11_000, tax_cents: 1_000, tender: :cash,
        cash_received_cents: 12_000, change_cents: 1_000
      )

      result = described_class.save(
        company: company, branch: branch, employee: employee,
        date: Date.new(2026, 11, 20),
        opening_float_cents: 5_000, counted_cash_cents: 15_500,
        note: "Two bills short"
      )

      saved = result[:shift_close]
      expect(saved[:opening_float_cents]).to eq(5_000)
      expect(saved[:expected_cash_cents]).to eq(16_000)
      expect(saved[:counted_cash_cents]).to eq(15_500)
      expect(saved[:variance_cents]).to eq(-500)
      expect(saved[:sales][:gross_sales_cents]).to eq(11_000)
      expect(saved[:open_handovers].first[:code]).to eq(order.code)

      reloaded = described_class.show(company: company, branch: branch, date: Date.new(2026, 11, 20))
      expect(reloaded[:saved]).to be(true)
      expect(reloaded[:variance_cents]).to eq(-500)
      expect(reloaded[:note]).to eq("Two bills short")
    end
  end

  it "still saves a day with no cash sales" do
    travel_to Time.utc(2026, 11, 20, 17, 0, 0) do
      create_store_invoice_order(
        company: company, branch: branch, employee: employee,
        total_cents: 5_000, tender: :qr
      )

      result = described_class.save(
        company: company, branch: branch, employee: employee,
        date: Date.new(2026, 11, 20),
        opening_float_cents: 0, counted_cash_cents: 0, note: nil
      )

      expect(result[:shift_close][:expected_cash_cents]).to eq(0)
      expect(result[:shift_close][:variance_cents]).to eq(0)
    end
  end

  it "requires a note when the variance is not zero" do
    travel_to Time.utc(2026, 11, 20, 17, 0, 0) do
      expect {
        described_class.save(
          company: company, branch: branch, employee: employee,
          date: Date.new(2026, 11, 20),
          opening_float_cents: 0, counted_cash_cents: 500, note: nil
        )
      }.to raise_error(ActiveRecord::RecordInvalid, /Note/)
    end
  end

  it "refuses to save a past date" do
    travel_to Time.utc(2026, 11, 20, 17, 0, 0) do
      expect {
        described_class.save(
          company: company, branch: branch, employee: employee,
          date: Date.new(2026, 11, 19),
          opening_float_cents: 0, counted_cash_cents: 0, note: nil
        )
      }.to raise_error(StoreManager::Error, "Only today's shift can be closed.")
    end
  end
end
