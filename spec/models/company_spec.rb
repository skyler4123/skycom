# spec/models/company_spec.rb
require 'rails_helper'

RSpec.describe Company, type: :model do
  describe "associations" do
    it { should belong_to(:user) }
    it { should have_many(:branches).dependent(:destroy) }
    it { should have_many(:tags).dependent(:destroy) }
    it { should have_many(:employee_groups).dependent(:destroy) }
    it { should have_many(:employees).dependent(:destroy) }
    it { should have_many(:roles).dependent(:destroy) }
    it { should have_many(:policies).dependent(:destroy) }
    it { should have_many(:facility_groups).dependent(:destroy) }
    it { should have_many(:facilities).dependent(:destroy) }
    it { should have_many(:service_groups).dependent(:destroy) }
    it { should have_many(:services).dependent(:destroy) }
    it { should have_many(:product_groups).dependent(:destroy) }
    it { should have_many(:products).dependent(:destroy) }
    it { should have_many(:customers).dependent(:destroy) }
    it { should have_many(:customer_groups).dependent(:destroy) }
    it { should have_many(:orders).dependent(:destroy) }
    it { should have_many(:payment_method_appointments).dependent(:destroy) }
    it { should have_many(:task_groups).dependent(:destroy) }
    it { should have_many(:project_groups).dependent(:destroy) }
    it { should have_many(:cart_groups).dependent(:destroy) }
    it { should have_many(:notification_groups).dependent(:destroy) }
    it { should have_many(:payment_methods).through(:payment_method_appointments) }
    it { should have_many(:categories).dependent(:destroy) }
    it { should have_many(:subscription_plans).dependent(:destroy) }
    it { should have_many(:departments).dependent(:destroy) }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:business_type) }
    it { should validate_length_of(:name).is_at_most(255) }
    it { should validate_length_of(:description).is_at_most(5000) }

    context "email format" do
      it { should allow_value("contact@company.com").for(:email) }
      it { should allow_value("").for(:email) }
      it { should_not allow_value("invalid-email").for(:email) }
    end

    context "website format" do
      it { should allow_value("https://example.com").for(:website) }
      it { should allow_value("http://example.com").for(:website) }
      it { should allow_value("").for(:website) }
      it { should_not allow_value("invalid-url").for(:website) }
    end

    context "phone number" do
      it { should validate_length_of(:phone_number).is_at_most(20) }
    end

    context "vat_id" do
      it { should validate_length_of(:vat_id).is_at_most(50) }
    end

    context "employee_count" do
      it { should validate_numericality_of(:employee_count).is_greater_than_or_equal_to(0) }
    end
  end

  describe "enums" do
    it { should define_enum_for(:country_code) }
    it { should define_enum_for(:business_type) }
    it { should define_enum_for(:lifecycle_status) }
    it { should define_enum_for(:workflow_status) }
    it { should define_enum_for(:timezone) }
    it { should define_enum_for(:currency_code) }
    it { should define_enum_for(:ownership_type) }
    it { should define_enum_for(:fiscal_year_end_month) }
  end

  describe "#create_first_cloned_company method exists" do
    it "responds to create_first_cloned_company" do
      expect(Company.new).to respond_to(:create_first_cloned_company)
    end
  end
end
