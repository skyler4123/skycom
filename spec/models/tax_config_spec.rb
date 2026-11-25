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

  describe "default tax code" do
    it "defaults to nil" do
      config = TaxConfig.for_company!(company)

      expect(config.default_tax_code_id).to be_nil
      expect(config.default_tax_code).to be_nil
    end

    it "stores a company tax code" do
      code = create(:tax_code, company: company)
      config = TaxConfig.for_company!(company)
      config.update!(default_tax_code_id: code.id)

      reloaded = TaxConfig.find(config.id)
      expect(reloaded.default_tax_code_id).to eq(code.id)
      expect(reloaded.default_tax_code).to eq(code)
    end

    it "rejects a tax code from another company" do
      code = create(:tax_code)
      config = TaxConfig.for_company!(company)

      config.default_tax_code_id = code.id

      expect(config).not_to be_valid
      expect(config.errors[:default_tax_code]).to be_present
    end

    it "rejects a discarded tax code" do
      code = create(:tax_code, company: company)
      code.discard!
      config = TaxConfig.for_company!(company)

      config.default_tax_code_id = code.id

      expect(config).not_to be_valid
      expect(config.errors[:default_tax_code]).to be_present
    end
  end
end
