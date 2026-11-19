require "rails_helper"

RSpec.describe TaxConfig, type: :model do
  let(:company) { create(:company) }

  it "creates a config with defaults via for_company!" do
    config = TaxConfig.for_company!(company)
    expect(config.date_basis).to eq("created_at")
    expect(config.include_invoices).to be(true)
    expect(config.include_purchases).to be(true)
    expect(config.include_stock_exports).to be(true)
    expect(config.excluded_invoice_statuses).to eq([])
    expect(config.stock_export_business_types).to eq([ "sale" ])
    expect(config.branch_ids).to eq([])
  end

  it "is unique per company" do
    TaxConfig.for_company!(company)
    expect { TaxConfig.create!(company: company) }.to raise_error(ActiveRecord::RecordInvalid)
  end

  it "stores settings in metadata via store_accessor" do
    config = TaxConfig.for_company!(company)
    config.update!(date_basis: "updated_at", branch_ids: [ "abc" ])
    reloaded = TaxConfig.find(config.id)
    expect(reloaded.date_basis).to eq("updated_at")
    expect(reloaded.branch_ids).to eq([ "abc" ])
    expect(reloaded.metadata).to include("date_basis" => "updated_at")
  end

  describe "POS tax" do
    it "defaults to no tax" do
      config = TaxConfig.for_company!(company)

      expect(config.pos_tax_rate_bp).to eq(0)
      expect(config.pos_tax_rate).to eq(0.0)
      expect(config.pos_tax_rate_percent).to eq(0.0)
      expect(config.pos_tax_name).to eq("Tax")
      expect(config.pos_tax?).to be(false)
    end

    it "stores basis points and exposes the rate" do
      config = TaxConfig.for_company!(company)
      config.update!(pos_tax_rate_bp: 825, pos_tax_name: "Sales tax")

      reloaded = TaxConfig.find(config.id)
      expect(reloaded.pos_tax_rate_bp).to eq(825)
      expect(reloaded.pos_tax_rate).to eq(0.0825)
      expect(reloaded.pos_tax_rate_percent).to eq(8.25)
      expect(reloaded.pos_tax_name).to eq("Sales tax")
      expect(reloaded.pos_tax?).to be(true)
    end

    it "rejects a rate above 100%" do
      config = TaxConfig.for_company!(company)
      config.pos_tax_rate_bp = 10_001

      expect(config).not_to be_valid
      expect(config.errors[:pos_tax_rate_bp]).to be_present
    end

    it "rejects a negative rate" do
      config = TaxConfig.for_company!(company)
      config.pos_tax_rate_bp = -1

      expect(config).not_to be_valid
    end
  end
end
