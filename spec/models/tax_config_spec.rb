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
end
