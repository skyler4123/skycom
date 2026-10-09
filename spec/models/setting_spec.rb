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
    it { should have_many(:setting_tag_appointments).dependent(:destroy) }
    it { should have_many(:tags).through(:setting_tag_appointments) }
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

  describe "dynamic sidebar storage" do
    it "defines the DYNAMIC_SIDEBAR_CODE constant" do
      expect(defined?(DYNAMIC_SIDEBAR_CODE)).to eq("constant")
      expect(DYNAMIC_SIDEBAR_CODE).to be_a(String)
    end

    it "reads sidebar_groups as [] when metadata is blank" do
      company = create(:company)
      setting = described_class.new(company: company, appoint_to: company)
      expect(setting.sidebar_groups).to eq([])
    end

    it "round-trips sidebar_groups through metadata" do
      company = create(:company)
      groups = [
        { "key" => "my-links", "name" => "My Links",
          "items" => [ { "key" => "pending-orders", "name" => "Pending Orders", "url" => "/orders?workflow_status=pending" } ] }
      ]
      setting = described_class.create!(
        company: company, appoint_to: company, code: DYNAMIC_SIDEBAR_CODE,
        lifecycle_status: :active, workflow_status: :confirmed, business_type: :company,
        sidebar_groups: groups
      )
      expect(setting.reload.sidebar_groups).to eq(groups)
      expect(setting.metadata["sidebar_groups"]).to eq(groups)
    end

    it "rejects sidebar_groups that are not an array" do
      company = create(:company)
      setting = described_class.new(
        company: company, appoint_to: company, code: DYNAMIC_SIDEBAR_CODE,
        lifecycle_status: :active, workflow_status: :confirmed, business_type: :company,
        sidebar_groups: "nope"
      )
      expect(setting).not_to be_valid
      expect(setting.errors[:sidebar_groups]).not_to be_empty
    end

    it "rejects groups without a name and items without name/url" do
      company = create(:company)
      setting = described_class.new(
        company: company, appoint_to: company, code: DYNAMIC_SIDEBAR_CODE,
        lifecycle_status: :active, workflow_status: :confirmed, business_type: :company,
        sidebar_groups: [ { "key" => "g1", "items" => [ { "key" => "i1", "name" => "", "url" => "" } ] } ]
      )
      expect(setting).not_to be_valid
      expect(setting.errors[:sidebar_groups]).not_to be_empty
    end

    it "enforces one dynamic sidebar record per company" do
      company = create(:company)
      described_class.create!(
        company: company, appoint_to: company, code: DYNAMIC_SIDEBAR_CODE,
        lifecycle_status: :active, workflow_status: :confirmed, business_type: :company,
        sidebar_groups: []
      )
      duplicate = described_class.new(
        company: company, appoint_to: company, code: DYNAMIC_SIDEBAR_CODE,
        lifecycle_status: :active, workflow_status: :confirmed, business_type: :company
      )
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:code]).not_to be_empty
    end
  end
end
