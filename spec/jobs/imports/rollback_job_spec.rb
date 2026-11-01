# frozen_string_literal: true

require "rails_helper"

RSpec.describe Imports::RollbackJob do
  let!(:company) { create(:company) }
  let(:category) { product_import_category(company: company) }

  before { allow(WEBSOCKET).to receive(:publish_event) }

  def completed_import
    import = create_import_with_file(company: company, category: category, csv: product_import_csv)
    Imports::DryRunService.call(import: import)
    import.reload.update!(workflow_status: :approved)
    Imports::RunService.call(import: import)
    import.reload.update!(workflow_status: :completed, completed_at: Time.current)
    import
  end

  def mark_rolling_back(import)
    import.update!(
      workflow_status: :rolling_back,
      metadata: import.metadata.merge("rollback_previous_status" => "completed")
    )
    import
  end

  describe "#perform" do
    it "transitions rolling_back → rolled_back and destroys the created records" do
      import = completed_import
      created_ids = import.import_logs.pluck(:record_id)
      mark_rolling_back(import)

      described_class.perform_now(import.id)
      import.reload

      expect(import.workflow_status).to eq("rolled_back")
      expect(import.rolled_back_at).to be_present
      expect(company.products.where(id: created_ids).count).to eq(0)
      expect(Notification.where(company: company, name: "Rollback of '#{import.name}' completed").count).to eq(1)
    end

    it "restores the previous status and notifies when the service fails" do
      import = completed_import
      mark_rolling_back(import)
      allow(Imports::RollbackService).to receive(:call).and_return(success: false, errors: [ "cannot delete" ])

      described_class.perform_now(import.id)
      import.reload

      expect(import.workflow_status).to eq("completed")
      expect(Notification.where(company: company, name: "Rollback of '#{import.name}' failed").count).to eq(1)
    end

    it "rescues exceptions into the previous status plus a notification" do
      import = completed_import
      mark_rolling_back(import)
      allow(Imports::RollbackService).to receive(:call).and_raise(RuntimeError, "boom")

      described_class.perform_now(import.id)
      import.reload

      expect(import.workflow_status).to eq("completed")
      expect(Notification.where(company: company).count).to eq(1)
    end

    it "is a no-op unless rolling back" do
      import = completed_import

      described_class.perform_now(import.id)
      import.reload

      expect(import.workflow_status).to eq("completed")
      expect(company.products.count).to eq(2)
      expect(Notification.count).to eq(0)
    end
  end
end
