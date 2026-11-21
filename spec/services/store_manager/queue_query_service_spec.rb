# frozen_string_literal: true

require "rails_helper"

RSpec.describe StoreManager::QueueQueryService, type: :service do
  let(:company) { create(:company) }
  let(:branch) { create(:branch, company: company, timezone: :utc) }
  let(:customer) { create(:customer, company: company, branch: branch, name: "Marcus Vance") }

  def open_order(channel: :click_collect, created_at: Time.utc(2026, 11, 20, 9, 0, 0), **attrs)
    order = create(
      :order,
      company: company,
      branch: branch,
      customer: customer,
      name: "Order #{SecureRandom.hex(6)}",
      workflow_status: :pending,
      fulfillment_channel: channel,
      created_at: created_at,
      **attrs
    )
    order.update_columns(discarded_at: nil)
    order
  end

  it "pages the whole day in 50-row slices" do
    travel_to Time.utc(2026, 11, 20, 12, 0, 0) do
      55.times { open_order }

      first = described_class.call(company: company, branch: branch, date: Date.new(2026, 11, 20),
        now: Time.utc(2026, 11, 20, 12, 0, 0), page: 1)
      second = described_class.call(company: company, branch: branch, date: Date.new(2026, 11, 20),
        now: Time.utc(2026, 11, 20, 12, 0, 0), page: 2)

      expect(first[:pagination]).to include(page: 1, per_page: 50, pages: 2, count: 55, from: 1, to: 50)
      expect(second[:pagination]).to include(page: 2, count: 55, from: 51, to: 55)
      expect(first[:orders].length).to eq(50)
      expect(second[:orders].length).to eq(5)
    end
  end

  it "finds the 55th order by its own code" do
    travel_to Time.utc(2026, 11, 20, 12, 0, 0) do
      orders = 55.times.map { open_order }
      target = orders.last

      payload = described_class.call(company: company, branch: branch, date: Date.new(2026, 11, 20),
        now: Time.utc(2026, 11, 20, 12, 0, 0), q: target.code)

      expect(payload[:orders].map { |row| row[:code] }).to eq([ target.code ])
      expect(payload[:pagination][:count]).to eq(1)
    end
  end

  it "searches channel and readiness labels" do
    travel_to Time.utc(2026, 11, 20, 12, 0, 0) do
      delivery = open_order(channel: :local_delivery)
      ready = open_order(channel: :click_collect)
      ready.update!(fulfillment_status: :ready)

      delivery_payload = described_class.call(company: company, branch: branch, date: Date.new(2026, 11, 20),
        now: Time.utc(2026, 11, 20, 12, 0, 0), q: "Local Delivery")
      ready_payload = described_class.call(company: company, branch: branch, date: Date.new(2026, 11, 20),
        now: Time.utc(2026, 11, 20, 12, 0, 0), q: "Ready")

      expect(delivery_payload[:orders].map { |row| row[:id] }).to eq([ delivery.id ])
      expect(ready_payload[:orders].map { |row| row[:id] }).to eq([ ready.id ])
    end
  end

  it "searches customer names through Meilisearch" do
    travel_to Time.utc(2026, 11, 20, 12, 0, 0) do
      elena = create(:customer, company: company, branch: branch, name: "Elena Rostova").tap { |record| record.ms_index!(true) }
      order = create(:order, company: company, branch: branch, customer: elena,
        name: "Order #{SecureRandom.hex(6)}", workflow_status: :pending,
        fulfillment_channel: :click_collect, created_at: Time.utc(2026, 11, 20, 9, 0, 0))
      order.update_columns(discarded_at: nil)

      payload = described_class.call(company: company, branch: branch, date: Date.new(2026, 11, 20),
        now: Time.utc(2026, 11, 20, 12, 0, 0), q: "Elena")

      expect(payload[:orders].map { |row| row[:id] }).to eq([ order.id ])
    end
  end

  it "uses the stored fulfilment channel, not business_type" do
    travel_to Time.utc(2026, 11, 20, 12, 0, 0) do
      order = open_order(channel: :local_delivery)
      order.update!(business_type: :in_store)

      payload = described_class.call(company: company, branch: branch, date: Date.new(2026, 11, 20),
        now: Time.utc(2026, 11, 20, 12, 0, 0))

      expect(payload[:orders].first).to include(channel_key: "local_delivery", channel_label: "Local Delivery")
    end
  end

  it "keeps an order open for the day it was created and completed for the day it was handed over" do
    travel_to Time.utc(2026, 11, 21, 10, 0, 0) do
      order = open_order(created_at: Time.utc(2026, 11, 20, 9, 0, 0))
      order.update!(fulfillment_status: :handed_over, handed_over_at: Time.utc(2026, 11, 21, 9, 0, 0))
      completed_yesterday = open_order(created_at: Time.utc(2026, 11, 20, 11, 0, 0))
      completed_yesterday.update!(fulfillment_status: :handed_over, handed_over_at: Time.utc(2026, 11, 20, 12, 0, 0))

      yesterday = described_class.call(company: company, branch: branch, date: Date.new(2026, 11, 20),
        now: Time.utc(2026, 11, 21, 10, 0, 0))

      expect(yesterday[:counts]).to include(all: 1, completed: 1)
      expect(yesterday[:orders].map { |row| row[:id] }).to eq([ order.id ])
    end
  end
end
