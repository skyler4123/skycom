# spec/models/page_spec.rb
require "rails_helper"

RSpec.describe Page, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should have_many(:branch_page_appointments).dependent(:destroy) }
    it { should have_many(:branches).through(:branch_page_appointments) }
    it { should have_many(:page_warehouse_appointments).dependent(:destroy) }
    it { should have_many(:warehouses).through(:page_warehouse_appointments) }
  end

  describe "enums" do
    it do
      should define_enum_for(:page_type).with_values(
        pos: 100,
        booking: 200,
        inventory: 300,
        reception: 400,
        kitchen: 500,
        housekeeping: 600,
        store_manager: 700
      ).with_prefix(:page_type)
    end

    it do
      should define_enum_for(:resolution).with_values(
        mobile: 10,
        desktop: 20
      ).with_prefix(:resolution)
    end
  end

  describe "validations" do
    subject { build(:page) }

    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:code) }
    it { should validate_presence_of(:page_type) }
    it { should validate_presence_of(:resolution) }

    it "requires metadata" do
      page = build(:page, metadata: nil)

      expect(page).not_to be_valid
      expect(page.errors[:metadata]).to include("can't be blank")
    end

    it "requires roles metadata to be an array of strings" do
      page = build(:page, metadata: { "roles" => "cashier" })

      expect(page).not_to be_valid
      expect(page.errors[:metadata]).to include("roles must be an array of strings")
    end

    it "allows empty roles metadata" do
      page = build(:page, metadata: { "roles" => [] })

      expect(page).to be_valid
    end

    it "requires the page type and resolution to be unique per company" do
      company = create(:company)
      create(:page, company: company, page_type: :pos, resolution: :desktop)
      duplicate = Page.new(
        company: company,
        page_type: :pos,
        resolution: :desktop,
        name: "Duplicate POS",
        code: "PG-DUP-#{SecureRandom.hex(3).upcase}"
      )

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:page_type]).to be_present
    end
  end

  describe "#config_for" do
    it "deep-merges appointment metadata with page metadata, page winning" do
      page = build(
        :page,
        metadata: {
          "layout" => { "columns" => 12, "sidebar" => "page" },
          "roles" => []
        }
      )
      appointment = BranchPageAppointment.new(
        metadata: {
          "layout" => { "columns" => 6, "sidebar" => "appointment", "theme" => "dark" },
          "roles" => [ "Cashier" ]
        }
      )

      expect(page.config_for(appointment)).to eq(
        "layout" => { "columns" => 12, "sidebar" => "page", "theme" => "dark" },
        "roles" => []
      )
    end

    it "returns page metadata when the appointment has none" do
      page = build(:page, metadata: { "roles" => [ "Cashier" ] })
      appointment = BranchPageAppointment.new(metadata: {})

      expect(page.config_for(appointment)).to eq("roles" => [ "Cashier" ])
    end
  end

  describe "#accessible_by?" do
    let(:company) { create(:company) }
    let(:branch) { create(:branch, company: company) }
    let(:employee) { create(:employee, company: company, branch: branch) }

    it "allows everyone with Page read when roles are empty" do
      page = create(:page, company: company, branch: branch, metadata: { "roles" => [] })

      expect(page.accessible_by?(employee)).to be(true)
    end

    it "allows an employee with a matching role" do
      employee.attach_role("Cashier")
      page = create(:page, company: company, branch: branch, metadata: { "roles" => [ "Cashier" ] })

      expect(page.accessible_by?(employee)).to be(true)
    end

    it "denies an employee without a matching role" do
      employee.attach_role("Cashier")
      page = create(:page, company: company, branch: branch, metadata: { "roles" => [ "Manager" ] })

      expect(page.accessible_by?(employee)).to be(false)
    end

    it "allows the owner regardless of roles" do
      owner = company.employees.find_by!(business_type: OWNER_BUSINESS_TYPE)
      owner.update!(branch: branch)
      page = create(:page, company: company, branch: branch, metadata: { "roles" => [ "Manager" ] })

      expect(page.accessible_by?(owner)).to be(true)
    end
  end
end
