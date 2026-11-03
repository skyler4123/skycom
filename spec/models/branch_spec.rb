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
    it { should have_many(:branch_payment_method_appointments).dependent(:destroy) }
    it { should have_many(:task_groups).dependent(:destroy) }
    it { should have_many(:project_groups).dependent(:destroy) }
    it { should have_many(:cart_groups).dependent(:destroy) }
    it { should have_many(:payment_methods).through(:branch_payment_method_appointments) }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:business_type) }
    it { should validate_length_of(:name).is_at_most(255) }
    it { should validate_length_of(:description).is_at_most(5000) }
  end

  describe "enums" do
    it { should define_enum_for(:country) }
    it { should define_enum_for(:business_type) }
    it { should define_enum_for(:currency) }
    it { should define_enum_for(:lifecycle_status) }
    it { should define_enum_for(:workflow_status) }

    # NOTE: ownership_type and fiscal_year_end_month columns were removed from schema
    # it { should define_enum_for(:ownership_type) }
    # it { should define_enum_for(:fiscal_year_end_month) }
  end

  describe "#subscription_buyer" do
    it "returns the company user" do
      company = create(:company)
      branch = create(:branch, company: company)
      expect(branch.subscription_buyer).to eq(company.user)
    end
  end

  describe "after_create default operating pages" do
    let(:company_user) { create(:user, :company_owner) }
    let(:company) { Seed::CompanyService.new(user: company_user, business_type: :retail).tap(&:save!) }

    around do |example|
      Company.skip_init = false
      example.run
    ensure
      Company.skip_init = true
    end

    it "creates the company catalog pages for the new branch" do
      branch = create(:branch, company: company)

      expect(company.pages.where(branch: branch).count).to eq(4)
      expect(company.pages.where(branch: branch).pluck(:name)).to contain_exactly(
        "Retail POS Desktop", "Retail POS Mobile",
        "Retail Store Manager Desktop", "Retail Store Manager Mobile"
      )
    end
  end

  describe "after_create payment method initialization" do
    let(:company) { create(:company) }
    let(:payment_method) { create(:payment_method) }

    before do
      company.update_column(:country, COUNTRY_CODES[:us])
    end

    it "copies active company-level payment method appointments to the new branch" do
      active_appointment = CompanyPaymentMethodAppointment.create!(
        company: company,
        payment_method: payment_method,
        name: "Cash for #{company.name}",
        code: "CSH-#{SecureRandom.hex(4).upcase}",
        business_type: :in_store,
        lifecycle_status: :active
      )

      branch = create(:branch, company: company)

      branch_appointment = branch.branch_payment_method_appointments.find_by(
        payment_method_id: active_appointment.payment_method_id
      )
      expect(branch_appointment).to be_present
      expect(branch_appointment.lifecycle_status).to eq("active")
      expect(branch_appointment.branch).to eq(branch)
      expect(branch_appointment.merchant_number).to eq(active_appointment.merchant_number)
      expect(branch_appointment.merchant_name).to eq(active_appointment.merchant_name)
      expect(branch_appointment.merchant_id).to eq(active_appointment.merchant_id)
    end

    it "does not copy inactive company-level payment method appointments" do
      CompanyPaymentMethodAppointment.create!(
        company: company,
        payment_method: payment_method,
        name: "Cash for #{company.name}",
        code: "CSH-#{SecureRandom.hex(4).upcase}",
        business_type: :in_store,
        lifecycle_status: :inactive
      )

      branch = create(:branch, company: company)

      expect(branch.branch_payment_method_appointments).to be_empty
    end
  end

  it_behaves_like "property_mapping concern", Branch
end
