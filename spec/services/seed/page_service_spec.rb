# frozen_string_literal: true

require "rails_helper"

RSpec.describe Seed::PageService do
  describe ".seed_defaults!" do
    it "creates one Page per page type for the company" do
      company = create(:company, business_type: :retail)

      described_class.seed_defaults!(company: company)

      expect(company.pages.count).to eq(PAGE_TYPES.size)
      expect(company.pages.pluck(:page_type)).to contain_exactly(*PAGE_TYPES.keys.map(&:to_s))
      expect(company.pages.pluck(:resolution).uniq).to eq([ "desktop" ])
    end

    it "uses the business-type display label and falls back to the catalog label" do
      retail = create(:company, business_type: :retail)
      hotel = create(:company, business_type: :hotel)

      described_class.seed_defaults!(company: retail)
      described_class.seed_defaults!(company: hotel)

      expect(retail.pages.find_by!(page_type: :pos).name).to eq("Retail POS")
      expect(hotel.pages.find_by!(page_type: :pos).name).to eq("Front Desk POS")
      expect(hotel.pages.find_by!(page_type: :kitchen).name).to eq("Kitchen")
    end

    it "is idempotent and keeps the generated code" do
      company = create(:company)
      described_class.seed_defaults!(company: company)
      code = company.pages.find_by!(page_type: :pos).code

      expect {
        described_class.seed_defaults!(company: company)
      }.not_to change { company.pages.count }

      expect(company.pages.find_by!(page_type: :pos).code).to eq(code)
    end

    it "creates branch appointments for branch-scoped page types" do
      company = create(:company)
      branch = create(:branch, company: company)

      described_class.seed_defaults!(company: company)

      branch_pages = company.pages.where(page_type: described_class.page_types_for_scope(:branch))
      expect(branch.branch_page_appointments.count).to eq(branch_pages.count)
      expect(branch.pages.pluck(:page_type)).to contain_exactly(*branch_pages.pluck(:page_type))
    end

    it "creates warehouse appointments only for warehouse-scoped page types" do
      company = create(:company)
      warehouse = create(:warehouse, company: company)

      described_class.seed_defaults!(company: company)

      expect(warehouse.page_warehouse_appointments.count).to eq(1)
      expect(warehouse.pages.pluck(:page_type)).to eq([ "inventory" ])
    end
  end

  describe ".ensure_appointments_for_branch!" do
    it "creates active appointments for every branch-scoped page" do
      company = create(:company)
      branch = create(:branch, company: company)
      described_class.seed_defaults!(company: company)
      branch.branch_page_appointments.delete_all

      expect {
        described_class.ensure_appointments_for_branch!(branch)
      }.to change { branch.branch_page_appointments.count }.by(described_class.page_types_for_scope(:branch).size)

      expect(branch.branch_page_appointments).to all(be_workflow_status_active)
    end
  end

  describe ".ensure_appointments_for_warehouse!" do
    it "creates an active inventory appointment" do
      company = create(:company)
      described_class.seed_defaults!(company: company)
      warehouse = create(:warehouse, company: company)

      described_class.ensure_appointments_for_warehouse!(warehouse)

      appointment = warehouse.page_warehouse_appointments.find_by!(page: company.pages.find_by!(page_type: :inventory))
      expect(appointment).to be_workflow_status_active
    end
  end

  describe ".create" do
    it "creates the page and appointments for existing locations" do
      company = create(:company)
      branch = create(:branch, company: company)
      warehouse = create(:warehouse, company: company)

      page = described_class.create(company: company, page_type: :inventory)

      expect(page).to be_persisted
      expect(branch.branch_page_appointments.where(page: page)).to be_empty
      expect(warehouse.page_warehouse_appointments.where(page: page).count).to eq(1)
    end
  end

  describe "Company init integration" do
    around do |example|
      Company.skip_init = false
      example.run
    ensure
      Company.skip_init = true
    end

    it "seeds the full catalog on company creation" do
      company = create(:company, business_type: :retail)

      expect(company.pages.count).to eq(PAGE_TYPES.size)
    end
  end
end
