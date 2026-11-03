# frozen_string_literal: true

require "rails_helper"

RSpec.describe Seed::PageService do
  let(:company) { create(:company, business_type: :retail) }
  let(:branch) { create(:branch, company: company) }

  describe ".ensure_defaults_for_branch!" do
    it "creates both resolutions for every retail page type" do
      pages = described_class.ensure_defaults_for_branch!(branch)

      expect(pages.size).to eq(4)
      expect(pages.map(&:target_role)).to contain_exactly(
        "retail_cashier", "retail_cashier", "retail_store_manager", "retail_store_manager"
      )
      expect(pages.map(&:target_resolution)).to contain_exactly(
        "mobile", "desktop", "mobile", "desktop"
      )
      expect(pages.map(&:name)).to contain_exactly(
        "Retail POS Desktop", "Retail POS Mobile",
        "Retail Store Manager Desktop", "Retail Store Manager Mobile"
      )
      expect(pages).to all(have_attributes(
        company: company,
        branch: branch,
        business_type: "retail",
        lifecycle_status: "active",
        workflow_status: "approved"
      ))
    end

    it "creates the restaurant catalog for restaurant companies" do
      restaurant = create(:company, business_type: :restaurant)
      restaurant_branch = create(:branch, company: restaurant)

      pages = described_class.ensure_defaults_for_branch!(restaurant_branch)

      expect(pages.size).to eq(6)
      expect(pages.map(&:target_role).uniq).to contain_exactly(
        "restaurant_cashier", "restaurant_waiter", "restaurant_kitchen_staff"
      )
    end

    it "is idempotent" do
      described_class.ensure_defaults_for_branch!(branch)

      expect {
        described_class.ensure_defaults_for_branch!(branch)
      }.not_to change { company.pages.count }
    end

    it "only marks the desktop retail cashier page as implemented" do
      pages = described_class.ensure_defaults_for_branch!(branch)
      cashier_desktop = pages.find { |p| p.target_role == "retail_cashier" && p.target_resolution == "desktop" }
      cashier_mobile = pages.find { |p| p.target_role == "retail_cashier" && p.target_resolution == "mobile" }

      expect(cashier_desktop.placeholder?).to be(false)
      expect(cashier_mobile.placeholder?).to be(true)
    end
  end

  describe ".new" do
    it "defaults the name from the catalog and target resolution" do
      page = described_class.new(
        company: company,
        branch: branch,
        target_role: :retail_cashier,
        target_resolution: :mobile
      )

      expect(page.name).to eq("Retail POS Mobile")
    end
  end
end
