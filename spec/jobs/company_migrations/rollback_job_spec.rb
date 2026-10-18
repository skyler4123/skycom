# frozen_string_literal: true

require "rails_helper"

RSpec.describe CompanyMigrations::RollbackJob do
  let!(:company) { create(:company) }

  let(:fixture) { Rails.root.join("faker/files/customers-10.csv") }

  before { allow(WEBSOCKET).to receive(:publish_event) }

  def completed_migration_with_import
    migration = create_migration_with_chunks(company: company, chunks: [ fixture ], config: customers_migration_config)
    CompanyMigrations::ImportService.call(company_migration: migration)
    migration.update!(workflow_status: :completed, completed_at: Time.current)
    migration
  end

  describe "#perform" do
    it "transitions rolling_back → rolled_back and notifies the owner" do
      migration = completed_migration_with_import
      migration.update!(workflow_status: :rolling_back)

      described_class.perform_now(migration.id)

      migration.reload
      expect(migration.workflow_status).to eq("rolled_back")
      expect(migration.rolled_back_at).to be_present
      expect(company.customers.count).to eq(0)
      expect(Notification.where(company: company, name: "Rollback of '#{migration.name}' completed").count).to eq(1)
    end

    it "is a no-op unless rolling_back" do
      migration = completed_migration_with_import

      described_class.perform_now(migration.id)

      expect(migration.reload.workflow_status).to eq("completed")
      expect(company.customers.count).to eq(10)
      expect(Notification.count).to eq(0)
    end

    it "returns to completed when the service fails" do
      migration = completed_migration_with_import
      migration.update!(workflow_status: :rolling_back)
      allow(CompanyMigrations::RollbackService).to receive(:call).and_return(success: false, errors: [ "boom" ])

      described_class.perform_now(migration.id)

      expect(migration.reload.workflow_status).to eq("completed")
      expect(Notification.where(company: company).count).to eq(1)
    end
  end
end
