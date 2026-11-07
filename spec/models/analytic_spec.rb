# frozen_string_literal: true

require "rails_helper"

RSpec.describe Analytic, type: :model do
  describe "associations" do
    it { should belong_to(:company).touch(true) }
  end

  describe "defaults" do
    it "returns every block when metadata has no blocks key" do
      analytic = described_class.new(company: create(:company), name: "Default")

      expect(analytic.blocks).to eq(described_class::BLOCKS)
    end

    it "returns the stored blocks when metadata has blocks" do
      analytic = create(:analytic, metadata: { "blocks" => %w[pillars revenue_mix] })

      expect(analytic.blocks).to eq(%w[pillars revenue_mix])
    end

    it "keeps an explicitly empty blocks array empty" do
      analytic = create(:analytic, metadata: { "blocks" => [] })

      expect(analytic.blocks).to eq([])
    end
  end

  describe "blocks validation" do
    it "rejects unknown block keys" do
      analytic = build(:analytic, metadata: { "blocks" => %w[pillars not_a_real_block] })

      expect(analytic).not_to be_valid
      expect(analytic.errors[:blocks]).to be_present
    end

    it "rejects duplicate block keys" do
      analytic = build(:analytic, metadata: { "blocks" => %w[pillars pillars] })

      expect(analytic).not_to be_valid
      expect(analytic.errors[:blocks]).to be_present
    end

    it "accepts a subset of known blocks" do
      analytic = build(:analytic, metadata: { "blocks" => %w[pillars revenue_mix] })

      expect(analytic).to be_valid
    end
  end

  describe "company.analytic" do
    it "returns the first analytic for the company" do
      company = create(:company)
      first = create(:analytic, company: company, name: "First")
      create(:analytic, company: company, name: "Second")

      expect(company.analytic).to eq(first)
    end

    it "creates a default analytic with every block when none exists" do
      company = create(:company)

      analytic = company.analytic

      expect(analytic).to be_persisted
      expect(analytic.company).to eq(company)
      expect(analytic.blocks).to eq(Analytic::BLOCKS)
    end
  end
end
