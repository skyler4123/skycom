# frozen_string_literal: true

require "rails_helper"

RSpec.describe CompanyMigrations::ImportJob do
  let!(:company) { create(:company) }

  let(:fixture) { Rails.root.join("faker/files/customers-10.csv") }

  before { allow(WEBSOCKET).to receive(:publish_event) }

  def approvable_migration
    migration = create_migration_with_chunks(company: company, chunks: [ fixture ], config: customers_migration_config)
    migration.update!(
      workflow_status: :approved,
      dry_run_result: { "passed" => true, "config_digest" => migration.config.digest }
    )
    migration
  end

  describe "#perform" do
    it "transitions approved → completed and notifies the owner exactly once" do
      migration = approvable_migration
      owner = company.employees.find_by(business_type: OWNER_BUSINESS_TYPE)

      described_class.perform_now(migration.id)

      migration.reload
      expect(migration.workflow_status).to eq("completed")
      expect(migration.completed_at).to be_present
      expect(company.customers.count).to eq(10)

      expect(Notification.where(company: company, name: "Migration '#{migration.name}' finished").count).to eq(1)
      tag = NotificationTag.find_by(company: company, name: MIGRATION_NOTIFICATION_TAG)
      expect(EmployeeNotificationTagAppointment.exists?(employee: owner, notification_tag: tag)).to be(true)
    end

    it "marks failed and notifies when the service fails" do
      migration = approvable_migration
      allow(CompanyMigrations::ImportService).to receive(:call).and_return(
        success: false,
        errors: [ "customers is missing a unique index on [company_id, external_id] — add it before importing" ]
      )

      described_class.perform_now(migration.id)

      migration.reload
      expect(migration.workflow_status).to eq("failed")
      expect(migration.error_samples.last["errors"]).to include(/missing a unique index/)
      expect(company.customers.count).to eq(0)
      expect(Notification.where(company: company, name: "Migration '#{migration.name}' failed").count).to eq(1)
    end

    it "is a no-op unless approved" do
      migration = create_migration_with_chunks(company: company, chunks: [ fixture ], config: customers_migration_config)

      described_class.perform_now(migration.id)

      expect(migration.reload.workflow_status).to eq("draft")
      expect(company.customers.count).to eq(0)
      expect(Notification.count).to eq(0)
    end

    it "rescues exceptions into failed plus a notification" do
      migration = approvable_migration
      allow(CompanyMigrations::ImportService).to receive(:call).and_raise(RuntimeError, "boom")

      described_class.perform_now(migration.id)

      migration.reload
      expect(migration.workflow_status).to eq("failed")
      expect(migration.error_samples.last["errors"].first).to eq("RuntimeError: boom")
      expect(Notification.where(company: company).count).to eq(1)
    end
  end
end
