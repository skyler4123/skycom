# spec/models/page_spec.rb
require "rails_helper"

RSpec.describe Page, type: :model do
  let(:company) { create(:company, business_type: :retail) }
  let(:branch) { create(:branch, company: company) }

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:branch) }
  end

  describe "enums" do
    it { should define_enum_for(:business_type).with_values(
      retail: 10, restaurant: 20, hospital: 30, education: 40, hotel: 50, fitness: 60
    ).with_prefix(:business_type) }

    it { should define_enum_for(:target_role).with_values(
      retail_cashier: 110, retail_store_manager: 120,
      restaurant_cashier: 210, restaurant_waiter: 220, restaurant_kitchen_staff: 230,
      hospital_receptionist: 310, hospital_doctor: 320, hospital_nurse: 330,
      education_receptionist: 410, education_teacher: 420, education_manager: 430,
      hotel_receptionist: 510, hotel_housekeeping: 520, hotel_manager: 530,
      fitness_receptionist: 610, fitness_trainer: 620, fitness_manager: 630
    ) }

    it { should define_enum_for(:target_resolution).with_values(
      mobile: 10, desktop: 20
    ).with_prefix(:target_resolution) }

    it { should define_enum_for(:lifecycle_status).with_values(
      active: 10, draft: 20, archived: 30
    ).with_prefix(:lifecycle_status) }

    it { should define_enum_for(:workflow_status).with_values(
      pending_review: 10, approved: 20, deployed: 30
    ).with_prefix(:workflow_status) }
  end

  describe "#name" do
    it "appends the target resolution on create" do
      page = Page.new(
        company: company,
        branch: branch,
        name: "Retail POS",
        target_role: :retail_cashier,
        target_resolution: :desktop
      )

      page.validate

      expect(page.name).to eq("Retail POS Desktop")
    end

    it "swaps the suffix when the target resolution changes" do
      page = create(
        :page,
        company: company,
        branch: branch,
        name: "Retail POS",
        target_role: :retail_cashier,
        target_resolution: :desktop
      )

      page.update!(target_resolution: :mobile)

      expect(page.name).to eq("Retail POS Mobile")
    end

    it "does not duplicate an existing suffix" do
      page = Page.new(
        company: company,
        branch: branch,
        name: "Retail POS Desktop",
        target_role: :retail_cashier,
        target_resolution: :desktop
      )

      page.validate

      expect(page.name).to eq("Retail POS Desktop")
    end
  end

  describe "#placeholder?" do
    it "is false only for the implemented desktop cashier page" do
      page = build(
        :page,
        company: company,
        branch: branch,
        target_role: :retail_cashier,
        target_resolution: :desktop
      )

      expect(page.placeholder?).to be(false)
    end

    it "is true for the mobile cashier page" do
      page = build(
        :page,
        company: company,
        branch: branch,
        target_role: :retail_cashier,
        target_resolution: :mobile
      )

      expect(page.placeholder?).to be(true)
    end

    it "is true for catalog pages that are not implemented" do
      page = build(
        :page,
        company: company,
        branch: branch,
        target_role: :retail_store_manager,
        target_resolution: :desktop
      )

      expect(page.placeholder?).to be(true)
    end
  end

  describe "validations" do
    it "rejects a business type that does not match the company" do
      page = build(
        :page,
        company: company,
        branch: branch,
        business_type: :restaurant,
        target_role: :retail_cashier,
        target_resolution: :desktop
      )

      expect(page).not_to be_valid
      expect(page.errors[:business_type]).to be_present
    end

    it "rejects a target role outside the company's catalog" do
      page = build(
        :page,
        company: company,
        branch: branch,
        target_role: :restaurant_cashier,
        target_resolution: :desktop
      )

      expect(page).not_to be_valid
      expect(page.errors[:target_role]).to be_present
    end

    it "rejects a branch that belongs to another company" do
      other_company = create(:company, business_type: :retail)
      other_branch = create(:branch, company: other_company)

      page = build(
        :page,
        company: company,
        branch: other_branch,
        target_role: :retail_cashier,
        target_resolution: :desktop
      )

      expect(page).not_to be_valid
      expect(page.errors[:branch]).to be_present
    end

    it "rejects a duplicate role and resolution for the same branch" do
      create(
        :page,
        company: company,
        branch: branch,
        target_role: :retail_cashier,
        target_resolution: :desktop
      )

      duplicate = build(
        :page,
        company: company,
        branch: branch,
        target_role: :retail_cashier,
        target_resolution: :desktop
      )

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:target_role]).to be_present
    end
  end

  describe ".target_roles_for" do
    it "returns the catalog roles for a business type" do
      expect(Page.target_roles_for(:retail)).to contain_exactly(:retail_cashier, :retail_store_manager)
      expect(Page.target_roles_for(:restaurant)).to include(:restaurant_cashier, :restaurant_waiter)
    end
  end

  describe ".counts_for" do
    before do
      create(:page, company: company, branch: branch, target_role: :retail_cashier, target_resolution: :desktop)
      create(:page, company: company, branch: branch, target_role: :retail_cashier, target_resolution: :mobile)
      create(:page, company: company, branch: branch, target_role: :retail_store_manager, target_resolution: :desktop)
      create(:page, company: company, branch: branch, target_role: :retail_store_manager, target_resolution: :mobile)
    end

    it "returns company-wide total, desktop, and mobile counts" do
      expect(Page.counts_for(company: company)).to eq(total: 4, desktop: 2, mobile: 2)
    end

    it "returns branch-scoped counts under a separate cache key" do
      other_branch = create(:branch, company: company)
      create(:page, company: company, branch: other_branch,
        target_role: :retail_cashier, target_resolution: :desktop)

      expect(Page.counts_for(company: company, branch_id: branch.id))
        .to eq(total: 4, desktop: 2, mobile: 2)
      expect(Page.counts_for(company: company))
        .to eq(total: 5, desktop: 3, mobile: 2)
    end

    it "caches the counts for one day" do
      expect(Page.counts_for(company: company)).to eq(total: 4, desktop: 2, mobile: 2)

      other_branch = create(:branch, company: company)
      create(:page, company: company, branch: other_branch,
        target_role: :retail_cashier, target_resolution: :desktop)

      expect(Page.counts_for(company: company)).to eq(total: 4, desktop: 2, mobile: 2)
    end
  end
end
