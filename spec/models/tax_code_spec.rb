# spec/models/tax_code_spec.rb
require "rails_helper"

RSpec.describe TaxCode, type: :model do
  describe "table" do
    it "uses tax_codes" do
      expect(described_class.table_name).to eq("tax_codes")
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:ledger_account).optional }
    it { should have_many(:products) }
    it { should have_many(:services) }
  end

  describe "validations" do
    it { should validate_length_of(:code).is_at_most(32) }
    it "has a presence validation for code on updates" do
      validator = described_class.validators_on(:code).detect { |v| v.is_a?(ActiveModel::Validations::PresenceValidator) }
      expect(validator).to be_present
    end
    it "declares code uniqueness scoped to company_id" do
      validator = described_class.validators_on(:code).detect { |v| v.is_a?(ActiveRecord::Validations::UniquenessValidator) }
      expect(validator).to be_present
      expect(Array(validator.options[:scope]).map(&:to_s)).to eq(%w[company_id])
    end
    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_most(255) }
    it { should validate_numericality_of(:rate_bp).only_integer.is_greater_than_or_equal_to(0).is_less_than_or_equal_to(10000) }
  end

  describe "enums" do
    it { should define_enum_for(:kind).with_prefix(true).with_values(vat: 0, gst: 1, sales: 2, withholding: 3) }
  end

  describe "discard" do
    it "is kept by default and leaves kept after discard!" do
      code = create(:tax_code)

      expect(code).not_to be_discarded
      code.discard!

      expect(code.reload).to be_discarded
      expect(described_class.kept).not_to include(code)
    end
  end

  describe "rate arithmetic" do
    it "converts basis points to a rate" do
      expect(described_class.new(rate_bp: 850).rate).to eq(0.085)
    end

    it "converts basis points to a percent" do
      expect(described_class.new(rate_bp: 850).rate_percent).to eq(8.5)
    end

    it "calculates tax on integer cents" do
      expect(described_class.new(rate_bp: 1_000).tax_for_cents(12_345)).to eq(1_235)
    end
  end

  describe "#breakdown_for" do
    it "adds tax on top for an exclusive code" do
      code = build(:tax_code, rate_bp: 1_000, is_inclusive: false)

      expect(code.breakdown_for(10_000)).to eq(taxable_cents: 10_000, tax_cents: 1_000)
    end

    it "extracts tax from a gross price for an inclusive code" do
      code = build(:tax_code, rate_bp: 1_000, is_inclusive: true)

      expect(code.breakdown_for(11_000)).to eq(taxable_cents: 10_000, tax_cents: 1_000)
    end

    it "returns zero tax at zero rate" do
      code = build(:tax_code, rate_bp: 0)

      expect(code.breakdown_for(10_000)).to eq(taxable_cents: 10_000, tax_cents: 0)
    end
  end

  describe "#option_payload" do
    it "returns the shared option shape" do
      code = create(:tax_code, code: "vat10", name: "VAT", rate_bp: 1_000, is_inclusive: true)

      expect(code.option_payload).to include(
        id: code.id,
        code: "VAT10",
        name: "VAT",
        rate_bp: 1_000,
        rate_percent: 10.0,
        inclusive: true
      )
    end
  end

  describe "code generation" do
    it "generates an uppercase code from the name when blank" do
      code = create(:tax_code, code: nil, name: "VAT 10%")

      expect(code.code).to eq("VAT_10")
    end
  end
end
