# frozen_string_literal: true

require "rails_helper"

RSpec.describe Imports::RunJob do
  let!(:company) { create(:company) }
  let(:category) { product_import_category(company: company) }

  before { allow(WEBSOCKET).to receive(:publish_event) }

  def approvable_import
    import = create_import_with_file(company: company, category: category, csv: product_import_csv)
    Imports::DryRunService.call(import: import)
    import.reload.update!(workflow_status: :approved)
    import
  end

  describe "#perform" do
    it "transitions approved → completed and notifies the creator exactly once" do
      import = approvable_import

      described_class.perform_now(import.id)
      import.reload

      expect(import.workflow_status).to eq("completed")
      expect(import.completed_at).to be_present
      expect(import.created_rows).to eq(2)
      expect(company.products.count).to eq(2)

      expect(Notification.where(company: company, name: "Import '#{import.name}' finished").count).to eq(1)
      tag = NotificationTag.find_by(company: company, name: IMPORT_NOTIFICATION_TAG)
      expect(EmployeeNotificationTagAppointment.exists?(employee: import.creator, notification_tag: tag)).to be(true)
    end

    it "marks failed and notifies when the service fails" do
      import = approvable_import
      allow(Imports::RunService).to receive(:call).and_return(
        success: false,
        errors: [ "Run a passing dry run before approving" ]
      )

      described_class.perform_now(import.id)
      import.reload

      expect(import.workflow_status).to eq("failed")
      expect(import.error_samples.last["errors"]).to include("Run a passing dry run before approving")
      expect(company.products.count).to eq(0)
      expect(Notification.where(company: company, name: "Import '#{import.name}' failed").count).to eq(1)
    end

    it "is a no-op unless approved" do
      import = create_import_with_file(company: company, category: category, csv: product_import_csv)

      described_class.perform_now(import.id)
      import.reload

      expect(import.workflow_status).to eq("draft")
      expect(company.products.count).to eq(0)
      expect(Notification.count).to eq(0)
    end

    it "rescues exceptions into failed plus a notification" do
      import = approvable_import
      allow(Imports::RunService).to receive(:call).and_raise(RuntimeError, "boom")

      described_class.perform_now(import.id)
      import.reload

      expect(import.workflow_status).to eq("failed")
      expect(import.error_samples.last["errors"].first).to eq("RuntimeError: boom")
      expect(Notification.where(company: company).count).to eq(1)
    end
  end
end
