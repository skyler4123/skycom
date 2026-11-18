# spec/models/exchange_rate_spec.rb
require "rails_helper"

RSpec.describe ExchangeRate, type: :model do
  describe "table" do
    it "uses exchange_rates" do
      expect(described_class.table_name).to eq("exchange_rates")
    end
  end

  describe "associations" do
    it { should belong_to(:company).optional }
  end

  describe "validations" do
    it { should validate_numericality_of(:rate).is_greater_than(0) }
    it { should validate_presence_of(:effective_on) }
  end

  describe "enums" do
    it { should define_enum_for(:base_currency).with_prefix(true).with_values(usd: 840, vnd: 704) }
    it { should define_enum_for(:quote_currency).with_prefix(true).with_values(usd: 840, vnd: 704) }
  end

describe "currency pair" do
  it "rejects a rate whose two currencies are the same" do
    rate = described_class.new(base_currency: :usd, quote_currency: :usd, rate: 1, effective_on: Date.current)
    rate.valid?

    expect(rate.errors[:quote_currency]).to include("must differ from the base currency")
  end

  it "accepts a real pair" do
    rate = described_class.new(base_currency: :usd, quote_currency: :vnd, rate: 25_000, effective_on: Date.current)
    rate.valid?

    expect(rate.errors[:quote_currency]).to eq([])
  end
end
end
