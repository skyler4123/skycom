# spec/models/company_setting_spec.rb
require "rails_helper"

RSpec.describe CompanySetting, type: :model do
  describe "associations" do
    it { should belong_to(:company).touch(true) }
  end

  describe "enums" do
    it "defines sidebar_groups and s3_storage business types" do
      expect(described_class.business_types.keys).to contain_exactly("sidebar_groups", "s3_storage")
    end

    it "defaults workflow_status to inactive" do
      company = create(:company)
      record = described_class.new(company: company, name: "Links", business_type: :sidebar_groups)
      expect(record.workflow_status).to eq("inactive")
    end
  end

  describe "name uniqueness" do
    it "requires a unique name within the company" do
      company = create(:company)
      described_class.create!(company: company, name: "Links", business_type: :sidebar_groups)
      duplicate = described_class.new(company: company, name: "Links", business_type: :s3_storage)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:name]).not_to be_empty
    end

    it "allows the same name in another company" do
      company_a = create(:company)
      company_b = create(:company)
      described_class.create!(company: company_a, name: "Links", business_type: :sidebar_groups)
      other = described_class.new(company: company_b, name: "Links", business_type: :sidebar_groups)
      expect(other).to be_valid
    end
  end

  describe "single active per business_type" do
    it "activates the first sidebar_groups record" do
      company = create(:company)
      record = described_class.create!(
        company: company, name: "Links v1", business_type: :sidebar_groups, workflow_status: :active
      )
      expect(record).to be_valid
      expect(described_class.active_sidebar.count).to eq(1)
    end

    it "rejects a second active record with the same business_type" do
      company = create(:company)
      described_class.create!(
        company: company, name: "Links v1", business_type: :sidebar_groups, workflow_status: :active
      )
      second = described_class.new(
        company: company, name: "Links v2", business_type: :sidebar_groups, workflow_status: :active
      )
      expect(second).not_to be_valid
      expect(second.errors[:workflow_status]).not_to be_empty
    end

    it "allows a second active record with a different business_type" do
      company = create(:company)
      described_class.create!(
        company: company, name: "Links", business_type: :sidebar_groups, workflow_status: :active
      )
      other = described_class.new(
        company: company, name: "Storage", business_type: :s3_storage, workflow_status: :active
      )
      expect(other).to be_valid
    end

    it "allows several inactive records with the same business_type" do
      company = create(:company)
      described_class.create!(
        company: company, name: "Links v1", business_type: :sidebar_groups, workflow_status: :inactive
      )
      second = described_class.new(
        company: company, name: "Links v2", business_type: :sidebar_groups, workflow_status: :inactive
      )
      expect(second).to be_valid
    end
  end

  describe "sidebar_groups storage" do
    it "reads sidebar_groups as [] when metadata is blank" do
      company = create(:company)
      record = described_class.new(company: company, name: "Links", business_type: :sidebar_groups)
      expect(record.sidebar_groups).to eq([])
    end

    it "round-trips sidebar_groups through metadata" do
      company = create(:company)
      groups = [
        { "key" => "my-links", "name" => "My Links",
          "items" => [ { "key" => "pending-orders", "name" => "Pending Orders", "url" => "/orders?workflow_status=pending" } ] }
      ]
      record = described_class.create!(
        company: company, name: "Links", business_type: :sidebar_groups, sidebar_groups: groups
      )
      expect(record.reload.sidebar_groups).to eq(groups)
      expect(record.metadata["sidebar_groups"]).to eq(groups)
    end

    it "rejects sidebar_groups that are not an array" do
      company = create(:company)
      record = described_class.new(
        company: company, name: "Links", business_type: :sidebar_groups, sidebar_groups: "nope"
      )
      expect(record).not_to be_valid
      expect(record.errors[:sidebar_groups]).not_to be_empty
    end

    it "rejects groups without a name and items without name/url" do
      company = create(:company)
      record = described_class.new(
        company: company, name: "Links", business_type: :sidebar_groups,
        sidebar_groups: [ { "key" => "g1", "items" => [ { "key" => "i1", "name" => "", "url" => "" } ] } ]
      )
      expect(record).not_to be_valid
      expect(record.errors[:sidebar_groups]).not_to be_empty
    end
  end

  describe "credentials" do
    it "encrypts and round-trips credential columns" do
      company = create(:company)
      record = described_class.create!(
        company: company, name: "Storage", business_type: :s3_storage,
        credential_1: "access-key", credential_2: "secret", credential_3: "region"
      )
      reloaded = described_class.find(record.id)
      expect(reloaded.credential_1).to eq("access-key")
      expect(reloaded.credential_2).to eq("secret")
      expect(reloaded.credential_3).to eq("region")
    end

    it "does not store credentials in plaintext" do
      company = create(:company)
      record = described_class.create!(
        company: company, name: "Storage", business_type: :s3_storage, credential_1: "access-key"
      )
      raw = described_class.connection.select_value(
        "SELECT credential_1 FROM company_settings WHERE id = '#{record.id}'"
      )
      expect(raw).not_to include("access-key")
    end

    it "resolves logical credential refs from metadata" do
      company = create(:company)
      record = described_class.create!(
        company: company, name: "Storage", business_type: :s3_storage,
        credential_1: "access-key",
        metadata: { "s3" => { "access_key_ref" => "credential_1" } }
      )
      expect(record.credential_for("s3", "access_key_ref")).to eq("access-key")
    end

    it "returns nil for unknown credential refs" do
      company = create(:company)
      record = described_class.new(company: company, name: "Storage", business_type: :s3_storage)
      expect(record.credential_for("s3", "access_key_ref")).to be_nil
    end
  end
end
