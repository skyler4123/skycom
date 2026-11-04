# spec/models/page_warehouse_appointment_spec.rb
require "rails_helper"

RSpec.describe PageWarehouseAppointment, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:page) }
    it { should belong_to(:warehouse) }
  end

  describe "enums" do
    it { should define_enum_for(:workflow_status).with_values(inactive: 0, active: 1).with_prefix(:workflow_status) }
    it { should define_enum_for(:lifecycle_status).with_prefix(:lifecycle_status) }
  end

  describe "validations" do
    it "derives company_id from the page" do
      company = create(:company)
      page = create(:page, company: company, page_type: :inventory)
      warehouse = create(:warehouse, company: company)
      appointment = described_class.new(page: page, warehouse: warehouse)

      expect(appointment).to be_valid
      expect(appointment.company_id).to eq(company.id)
    end

    it "rejects a warehouse from another company" do
      company = create(:company)
      other_company = create(:company)
      page = create(:page, company: company, page_type: :inventory)
      warehouse = create(:warehouse, company: other_company)
      appointment = described_class.new(company: company, page: page, warehouse: warehouse)

      expect(appointment).not_to be_valid
      expect(appointment.errors[:warehouse]).to include("does not belong to this company")
    end

    it "requires a unique warehouse per company and page" do
      company = create(:company)
      page = create(:page, company: company, page_type: :inventory)
      warehouse = create(:warehouse, company: company)
      create(:page_warehouse_appointment, company: company, page: page, warehouse: warehouse)
      duplicate = build(:page_warehouse_appointment, company: company, page: page, warehouse: warehouse)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:page_id]).to be_present
    end
  end

  describe ".active" do
    it "returns only active appointments" do
      company = create(:company)
      page = create(:page, company: company, page_type: :inventory)
      warehouse = create(:warehouse, company: company)
      active = create(:page_warehouse_appointment, company: company, page: page, warehouse: warehouse)
      create(:page_warehouse_appointment, :inactive, company: company, page: page, warehouse: create(:warehouse, company: company))

      expect(described_class.active).to contain_exactly(active)
    end
  end
end
