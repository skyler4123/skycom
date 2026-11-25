# spec/models/service_spec.rb
require 'rails_helper'

RSpec.describe Service, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:branch).optional }
    it { should belong_to(:tax_code).optional }
    it { should have_many(:order_service_appointments).dependent(:destroy) }
    it { should have_many(:orders).through(:order_service_appointments) }
    it { should have_many(:service_service_group_appointments).dependent(:destroy) }
    it { should have_many(:service_groups).through(:service_service_group_appointments) }
    it { should have_many(:customer_group_service_appointments).dependent(:destroy) }
    it { should have_many(:customer_groups).through(:customer_group_service_appointments) }
    it { should have_many(:customer_service_appointments).dependent(:destroy) }
    it { should have_many(:customers).through(:customer_service_appointments) }
    it { should have_many(:employee_service_appointments).dependent(:destroy) }
    it { should have_many(:employees).through(:employee_service_appointments) }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:business_type) }
    it { should validate_length_of(:name).is_at_most(255) }
    it { should validate_length_of(:description).is_at_most(5000) }

    it "rejects a tax code from another company" do
      company = create(:company)
      category = Seed::CategoryService.find_or_create_for(company: company, resource_name: "services")
      service = Service.new(
        company: company,
        name: "Tax validation service",
        business_type: :b2c,
        category: category,
        property_mapping: category.default_property_mapping,
        tax_code: create(:tax_code)
      )

      expect(service).not_to be_valid
      expect(service.errors[:tax_code]).to be_present
    end
  end

  describe "enums" do
    it { should define_enum_for(:lifecycle_status) }
    it { should define_enum_for(:workflow_status) }
    it { should define_enum_for(:business_type).with_values(b2b: 0, b2c: 1) }
  end
  it_behaves_like "property_mapping concern", Service
end
