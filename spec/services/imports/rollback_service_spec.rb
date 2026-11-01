# frozen_string_literal: true

require "rails_helper"

RSpec.describe Imports::RollbackService do
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

  it "destroys only the records this import created and keeps the logs" do
    existing = create(:product, company: company, name: "Existing Product")
    import = completed_import
    created_ids = import.import_logs.pluck(:record_id)

    result = described_class.call(import: import)
    import.reload

    expect(result[:success]).to be(true)
    expect(company.products.where(id: created_ids).count).to eq(0)
    expect(company.products.where(id: existing.id).exists?).to be(true)
    expect(import.import_logs.count).to eq(2)
    expect(import.metadata["rollback_processed"]).to eq(2)
    expect(import.metadata["rollback_total"]).to eq(2)
  end

  it "tolerates records deleted after the import" do
    import = completed_import
    company.products.find_by!(name: "Imported Serum").destroy!

    expect { described_class.call(import: import) }.not_to raise_error
  end

  it "is idempotent" do
    import = completed_import

    described_class.call(import: import)
    result = described_class.call(import: import)

    expect(result[:success]).to be(true)
    expect(company.products.count).to eq(0)
  end
end
