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
    it { should define_enum_for(:country) }
    it { should define_enum_for(:business_type) }
    it { should define_enum_for(:lifecycle_status) }
    it { should define_enum_for(:workflow_status) }
    it { should define_enum_for(:timezone) }
    it { should define_enum_for(:currency) }
    it { should define_enum_for(:ownership_type) }
    it { should define_enum_for(:fiscal_year_end_month) }
  end

  describe "lifecycle_status" do
    it "defines company-specific lifecycle values" do
      expect(Company.lifecycle_statuses).to eq({
        "active" => 0,
        "disabled" => 30
      })
    end

    it "defaults to active" do
      expect(Company.new.lifecycle_status).to eq("active")
    end
  end

  describe "#create_first_cloned_company method exists" do
    it "responds to create_first_cloned_company" do
      expect(Company.new).to respond_to(:create_first_cloned_company)
    end
  end

  describe "#setup_payment_method_appointments" do
    let(:company) { create(:company).tap { |c| c.update_column(:country, 840) } }

    before do
      create(:payment_method, code: "CASH_US", strategy: :cash, country: 840)
      create(:payment_method, code: "STRIPE_US", strategy: :stripe_gateway, country: 840)
      create(:payment_method, code: "CASH_VN", strategy: :cash, country: 704)
    end

    it "creates appointments for all PaymentMethods matching the company's country" do
      expect { company.setup_payment_method_appointments }
        .to change(PaymentMethodAppointment, :count).by(2)
    end

    it "creates appointments with lifecycle_status: :active for cash strategies" do
      company.setup_payment_method_appointments
      cash_appt = company.payment_method_appointments.joins(:payment_method).find_by(payment_method: { strategy: :cash })
      expect(cash_appt.lifecycle_status).to eq("active")
    end

    it "creates appointments with lifecycle_status: :inactive for non-cash strategies" do
      company.setup_payment_method_appointments
      stripe_appt = company.payment_method_appointments.joins(:payment_method).find_by(payment_method: { strategy: :stripe_gateway })
      expect(stripe_appt.lifecycle_status).to eq("inactive")
    end

    it "creates appointments with business_type: :in_store" do
      company.setup_payment_method_appointments
      expect(company.payment_method_appointments).to all(have_attributes(business_type: "in_store"))
    end

    it "is idempotent on re-run" do
      company.setup_payment_method_appointments
      expect { company.setup_payment_method_appointments }
        .not_to change(PaymentMethodAppointment, :count)
    end

    it "does not create appointments for non-matching countries" do
      company.setup_payment_method_appointments
      vn_pm = PaymentMethod.find_by(code: "CASH_VN")
      expect(company.payment_method_appointments.where(payment_method: vn_pm)).to be_empty
    end
  end

  describe "credit wallet" do
    it "auto-creates a company wallet on create" do
      company = create(:company)
      expect(company.company_wallet).to be_present
      expect(company.company_wallet.main_credit_balance).to eq(0)
      expect(company.company_wallet.walletable).to eq(company)
    end
  end

  describe "credit usage counter (Kredis)" do
    let(:company) { create(:company) }

    it "records usage into the credit usage counter" do
      company.record_credit_usage!(10)
      company.record_credit_usage!(5)

      expect(company.credit_usage.value).to eq(15)
      expect(company.credit_usage_delta).to eq(15)
    end

    it "returns zero deltas when nothing was recorded" do
      expect(company.credit_usage_delta).to eq(0)
    end

    it "ignores non-positive or non-integer credits" do
      company.record_credit_usage!(0)
      company.record_credit_usage!(-5)
      company.record_credit_usage!("10")
      expect(company.credit_usage_delta).to eq(0)
    end
  end

  describe "payment method appointment merchant seeding" do
    let!(:pm_cash) do
      PaymentMethod.create!(name: "Spec Cash", code: "SPEC_CASH", business_type: :b2c,
        payment_mode: :cash, strategy: :cash)
    end
    let!(:pm_qr) do
      PaymentMethod.create!(name: "Spec Mock QR", code: "SPEC_MQR", business_type: :b2c,
        payment_mode: :qr, strategy: :mock_qr_gateway)
    end
    let!(:pm_redirect) do
      PaymentMethod.create!(name: "Spec Mock Redirect", code: "SPEC_RD", business_type: :b2c,
        payment_mode: :redirect, strategy: :mock_redirect_gateway)
    end
    let(:company_user) { create(:user, :company_owner) }
    let(:company) { Seed::CompanyService.new(user: company_user, country: :us, business_type: :education).tap(&:save!) }

    around do |example|
      Company.skip_init = false
      example.run
    ensure
      Company.skip_init = true
    end

    it "fills merchant account, name and terminal id for qr-mode appointments" do
      appt = company.payment_method_appointments.find_by(payment_method: pm_qr)
      expect(appt.merchant_number).to match(/\A\d{10}\z/)
      expect(appt.merchant_name).to eq(company.name)
      expect(appt.merchant_id).to start_with("T-")
    end

    it "fills only a terminal id for redirect-mode appointments" do
      appt = company.payment_method_appointments.find_by(payment_method: pm_redirect)
      expect(appt.merchant_id).to start_with("MID-")
      expect(appt.merchant_number).to be_nil
      expect(appt.merchant_name).to be_nil
    end

    it "leaves cash appointments without merchant data" do
      appt = company.payment_method_appointments.find_by(payment_method: pm_cash)
      expect(appt.merchant_number).to be_nil
      expect(appt.merchant_name).to be_nil
      expect(appt.merchant_id).to be_nil
    end
  end
end
