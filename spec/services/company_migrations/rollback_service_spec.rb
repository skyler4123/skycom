# frozen_string_literal: true

require "rails_helper"

RSpec.describe CompanyMigrations::RollbackService do
  let!(:company) { create(:company) }

  let(:fixture) { Rails.root.join("faker/files/customers-10.csv") }

  let(:websocket_events) { [] }

  before do
    allow(WEBSOCKET).to receive(:publish_event) { |**kwargs| websocket_events << kwargs }
  end

  def completed_migration_with_import
    migration = create_migration_with_chunks(company: company, chunks: [ fixture ], config: customers_migration_config)
    CompanyMigrations::ImportService.call(company_migration: migration)
    migration.update!(workflow_status: :completed, completed_at: Time.current)
    migration
  end

  def rollback(migration)
    described_class.call(company_migration: migration)
  end

  describe "a successful rollback" do
    it "destroys records logged as created and keeps the logs as audit" do
      migration = completed_migration_with_import
      expect(company.customers.count).to eq(10)

      result = rollback(migration)

      expect(result[:success]).to be(true)
      expect(company.customers.count).to eq(0)
      expect(migration.company_migration_logs.count).to eq(10)
    end

    it "restores previous values for records logged as updated" do
      existing = create(:customer, company: company, external_id: "dE014d010c7ab0c")
      existing.update_columns(name: "Pre-existing")
      migration = completed_migration_with_import
      expect(existing.reload.name).to eq("Andrew")

      existing.update_columns(name: "Changed After Import")

      result = rollback(migration)

      expect(result[:success]).to be(true)
      expect(existing.reload.name).to eq("Pre-existing")
      expect(company.customers.where(external_id: "dE014d010c7ab0c").count).to eq(1)
    end

    it "tolerates records deleted after import" do
      migration = completed_migration_with_import
      company.customers.first.destroy!

      result = rollback(migration)

      expect(result[:success]).to be(true)
      expect(company.customers.count).to eq(0)
    end

    it "is idempotent on re-run" do
      migration = completed_migration_with_import
      rollback(migration)

      result = rollback(migration)

      expect(result[:success]).to be(true)
      expect(company.customers.count).to eq(0)
    end

    it "reports rollback progress and totals in metadata" do
      migration = completed_migration_with_import

      rollback(migration)

      migration.reload
      expect(migration.rollback_total).to eq(10)
      expect(migration.rollback_processed).to eq(10)

      rollback_events = websocket_events.select do |event|
        event[:event_key] == :company_migration_progress && event[:data][:phase] == "rollback"
      end
      expect(rollback_events).to be_present
      expect(rollback_events.last[:data][:processed_rows]).to eq(10)
      expect(rollback_events.last[:data][:total_rows]).to eq(10)
    end
  end
end
