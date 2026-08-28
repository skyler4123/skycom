# spec/models/setting_spec.rb
require 'rails_helper'

RSpec.describe Setting, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:setting_group).optional }
    it { should belong_to(:appoint_to) }
    it { should belong_to(:appoint_from).optional }
    it { should belong_to(:appoint_for).optional }
    it { should belong_to(:appoint_by).optional }
    it { should have_many(:tag_appointments).dependent(:destroy) }
    it { should have_many(:tags).through(:tag_appointments) }
  end

  describe "store_accessor" do
    it "exposes sidebar_items from metadata" do
      company = create(:company)
      setting = described_class.new(
        company: company,
        appoint_to: company,
        sidebar_items: [ { "key" => "products", "visible" => true } ]
      )
      expect(setting.sidebar_items).to eq([ { "key" => "products", "visible" => true } ])
      expect(setting.metadata).to eq({ "sidebar_items" => [ { "key" => "products", "visible" => true } ] })
    end
  end

  describe "#derive_company_from_appoint_to" do
    it "sets company_id from a Company appoint_to" do
      company = create(:company)
      setting = described_class.new(appoint_to: company)
      setting.valid?
      expect(setting.company_id).to eq(company.id)
    end

    it "sets company_id from a Branch appoint_to's company" do
      company = create(:company)
      branch = create(:branch, company: company)
      setting = described_class.new(appoint_to: branch)
      setting.valid?
      expect(setting.company_id).to eq(company.id)
    end

    it "does not override an existing company_id" do
      company = create(:company)
      other = create(:company)
      setting = described_class.new(company: company, appoint_to: other)
      setting.valid?
      expect(setting.company_id).to eq(company.id)
    end
  end

  describe "company_level scope" do
    it "returns only settings appointed to a Company" do
      company = create(:company)
      company_setting = described_class.create!(
        company: company, appoint_to: company, code: "COMPANY",
        lifecycle_status: :active, workflow_status: :confirmed, business_type: :system
      )
      branch = create(:branch, company: company)
      branch_setting = described_class.create!(
        company: company, appoint_to: branch, code: "BRANCH",
        lifecycle_status: :active, workflow_status: :confirmed, business_type: :system
      )

      expect(described_class.company_level).to include(company_setting)
      expect(described_class.company_level).not_to include(branch_setting)
      expect(described_class.company_level.map(&:appoint_to_type)).to all(eq("Company"))
    end
  end
end
