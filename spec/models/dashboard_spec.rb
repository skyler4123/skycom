# frozen_string_literal: true

require "rails_helper"

RSpec.describe Dashboard, type: :model do
  describe "associations" do
    it { should belong_to(:company).touch(true) }
  end

  describe "defaults" do
    it "returns every block when metadata has no blocks key" do
      dashboard = described_class.new(company: create(:company), name: "Default")

      expect(dashboard.blocks).to eq(described_class::BLOCKS)
    end

    it "returns the stored blocks when metadata has blocks" do
      dashboard = create(:dashboard, metadata: { "blocks" => %w[kpis company_wallet] })

      expect(dashboard.blocks).to eq(%w[kpis company_wallet])
    end

    it "keeps an explicitly empty blocks array empty" do
      dashboard = create(:dashboard, metadata: { "blocks" => [] })

      expect(dashboard.blocks).to eq([])
    end
  end

  describe "blocks validation" do
    it "rejects unknown block keys" do
      dashboard = build(:dashboard, metadata: { "blocks" => %w[kpis not_a_real_block] })

      expect(dashboard).not_to be_valid
      expect(dashboard.errors[:blocks]).to be_present
    end

    it "rejects duplicate block keys" do
      dashboard = build(:dashboard, metadata: { "blocks" => %w[kpis kpis] })

      expect(dashboard).not_to be_valid
      expect(dashboard.errors[:blocks]).to be_present
    end

    it "accepts a subset of known blocks" do
      dashboard = build(:dashboard, metadata: { "blocks" => %w[kpis company_meta] })

      expect(dashboard).to be_valid
    end
  end

  describe "company.dashboard" do
    it "returns the first dashboard for the company" do
      company = create(:company)
      first = create(:dashboard, company: company, name: "First")
      create(:dashboard, company: company, name: "Second")

      expect(company.dashboard).to eq(first)
    end

    it "creates a default dashboard with every block when none exists" do
      company = create(:company)

      dashboard = company.dashboard

      expect(dashboard).to be_persisted
      expect(dashboard.company).to eq(company)
      expect(dashboard.blocks).to eq(Dashboard::BLOCKS)
    end
  end
end
