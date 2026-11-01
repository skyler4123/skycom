# frozen_string_literal: true

require "rails_helper"

RSpec.describe Imports::SetupService do
  let!(:company) { create(:company) }
  let(:creator) { owner_of(company) }

  it "creates the shared Imports root, a child folder, and a draft import" do
    import = described_class.call(company: company, creator: creator, name: "Products 2026-11", description: "Q4 catalog")

    expect(import).to be_persisted
    expect(import.workflow_status).to eq("draft")
    expect(import.creator).to eq(creator)
    expect(import.description).to eq("Q4 catalog")
    expect(import.folder.parent&.name).to eq("Imports")
    expect(import.folder.name).to eq("Products 2026-11")
  end

  it "reuses the Imports root across imports" do
    first = described_class.call(company: company, creator: creator, name: "First")
    second = described_class.call(company: company, creator: creator, name: "Second")

    expect(first.folder.parent).to eq(second.folder.parent)
    expect(company.folders.where(parent_id: nil, name: "Imports").count).to eq(1)
  end

  it "rolls the child folder back when the import name is invalid" do
    expect {
      described_class.call(company: company, creator: creator, name: nil)
    }.to raise_error(ActiveRecord::RecordInvalid)

    expect(company.folders.where.not(parent_id: nil).count).to eq(0)
  end
end
