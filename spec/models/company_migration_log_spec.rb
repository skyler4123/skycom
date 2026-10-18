# frozen_string_literal: true

require "rails_helper"

RSpec.describe CompanyMigrationLog, type: :model do
  let!(:company) { create(:company) }

  describe "action" do
    it "maps created/updated actions" do
      expect(described_class.actions).to eq("created" => 0, "updated" => 1)
    end

    it "is invalid without an action" do
      log = build(:company_migration_log, company: company, action: nil)

      expect(log).not_to be_valid
      expect(log.errors[:action]).to be_present
    end
  end

  describe "#record" do
    it "associates with an imported record polymorphically" do
      customer = create(:customer, company: company)
      log = create(:company_migration_log,
                   company: company,
                   company_migration: create(:company_migration, company: company),
                   record: customer)

      log.reload

      expect(log.record).to eq(customer)
      expect(log.record_type).to eq("Customer")
    end
  end

  describe "previous_state" do
    it "defaults to an empty object" do
      expect(described_class.new.previous_state).to eq({})
    end
  end

  describe "uniqueness per record" do
    it "keeps one log per [migration, record type, record_id]" do
      migration = create(:company_migration, company: company)
      attributes = {
        company_migration_id: migration.id,
        company_id: company.id,
        record_type: "Customer",
        record_id: SecureRandom.uuid,
        action: 0,
        previous_state: {},
        created_at: Time.current,
        updated_at: Time.current
      }

      CompanyMigrationLog.insert_all([ attributes ], unique_by: "idx_company_migration_logs_unique_record")
      CompanyMigrationLog.insert_all([ attributes ], unique_by: "idx_company_migration_logs_unique_record")

      expect(CompanyMigrationLog.where(company_migration: migration).count).to eq(1)
    end
  end
end
