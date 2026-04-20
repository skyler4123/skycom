# spec/models/branch_spec.rb
require 'rails_helper'

RSpec.describe Branch, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
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
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:business_type) }
    it { should validate_length_of(:name).is_at_most(255) }
    it { should validate_length_of(:description).is_at_most(5000) }
  end

  describe "enums" do
    it { should define_enum_for(:country_code) }
    it { should define_enum_for(:business_type) }
    it { should define_enum_for(:timezone) }
    it { should define_enum_for(:currency_code) }
    it { should define_enum_for(:lifecycle_status) }
    it { should define_enum_for(:workflow_status) }
    it { should define_enum_for(:ownership_type) }
    it { should define_enum_for(:fiscal_year_end_month) }
  end

  describe "#subscription_buyer" do
    it "returns the company user" do
      company = create(:company)
      branch = create(:branch, company: company)
      expect(branch.subscription_buyer).to eq(company.user)
    end
  end
end
