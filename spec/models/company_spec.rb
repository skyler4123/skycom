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
      expect(company.wallet).to be_present
      expect(company.wallet.credit_balance).to eq(0)
      expect(company.wallet.walletable).to eq(company)
    end
  end

  describe "credit usage counters (Kredis)" do
    let(:company) { create(:company) }
    let(:date) { Date.new(2026, 8, 18) }

    it "records usage into daily and hourly counters" do
      company.record_credit_usage!(10, at: Time.zone.local(2026, 8, 18, 14, 30))
      company.record_credit_usage!(5, at: Time.zone.local(2026, 8, 18, 14, 45))

      expect(Kredis.counter(Company.credit_usage_day_key(company.id, date)).value).to eq(15)
      expect(Kredis.counter(Company.credit_usage_hour_key(company.id, date, 14)).value).to eq(15)
      expect(company.credit_usage_delta(date: date)).to eq(15)
      expect(company.credit_usage_delta(date: date, hour: 14)).to eq(15)
    end

    it "returns zero deltas when nothing was recorded" do
      expect(company.credit_usage_delta(date: date)).to eq(0)
    end
  end
end
