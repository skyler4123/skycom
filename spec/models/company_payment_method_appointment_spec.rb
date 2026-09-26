# spec/models/company_payment_method_appointment_spec.rb
require 'rails_helper'

RSpec.describe CompanyPaymentMethodAppointment, type: :model do
  describe "associations" do
    it { should belong_to(:payment_method) }
    it { should belong_to(:company) }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:code) }
    it { should validate_presence_of(:business_type) }
  end

  describe "enums" do
    it { should define_enum_for(:lifecycle_status) }
    it { should define_enum_for(:workflow_status) }
    it { should define_enum_for(:business_type).with_values(online: 0, in_store: 1, recurring: 2) }
  end

  describe "lifecycle cascade" do
    let(:company) { create(:company) }
    let(:payment_method) { create(:payment_method) }

    before { company.update_column(:country, COUNTRY_CODES[:us]) }

    it "mirrors lifecycle_status changes to branch-level appointments" do
      company_appointment = CompanyPaymentMethodAppointment.create!(
        company: company,
        payment_method: payment_method,
        name: "Cash for #{company.name}",
        code: "CSH-#{SecureRandom.hex(4).upcase}",
        business_type: :in_store,
        lifecycle_status: :active
      )
      # New branches auto-inherit active company payments via Branch#initialize_payment_methods
      branch = create(:branch, company: company)
      branch_appointment = branch.branch_payment_method_appointments.find_by!(payment_method: payment_method)

      company_appointment.update!(lifecycle_status: :inactive)

      expect(branch_appointment.reload.lifecycle_status).to eq("inactive")
    end

    it "does not cascade to branch appointments of other payment methods" do
      other_payment_method = create(:payment_method)
      company_appointment = CompanyPaymentMethodAppointment.create!(
        company: company,
        payment_method: payment_method,
        name: "Cash for #{company.name}",
        code: "CSH-#{SecureRandom.hex(4).upcase}",
        business_type: :in_store,
        lifecycle_status: :active
      )
      CompanyPaymentMethodAppointment.create!(
        company: company,
        payment_method: other_payment_method,
        name: "Other for #{company.name}",
        code: "OTH-#{SecureRandom.hex(4).upcase}",
        business_type: :in_store,
        lifecycle_status: :active
      )
      branch = create(:branch, company: company)
      other_branch_appointment = branch.branch_payment_method_appointments.find_by!(payment_method: other_payment_method)

      company_appointment.update!(lifecycle_status: :inactive)

      expect(other_branch_appointment.reload.lifecycle_status).to eq("active")
    end
  end

  describe "country code validation" do
    let(:company) { create(:company) }
    let(:payment_method) { create(:payment_method) }
    let(:country_us) { COUNTRY_CODES[:us] }
    let(:country_vn) { COUNTRY_CODES[:vn] }

    before do
      company.update_column(:country, country_us)
    end

    context "when country codes match" do
      before do
        payment_method.update_column(:country, country_us)
      end

      it "is valid" do
        appointment = build(:company_payment_method_appointment, company: company, payment_method: payment_method)
        expect(appointment).to be_valid
      end
    end

    context "when country codes do not match" do
      before do
        payment_method.update_column(:country, country_vn)
      end

      it "is invalid with a mismatch error" do
        appointment = build(:company_payment_method_appointment, company: company, payment_method: payment_method)
        expect(appointment).not_to be_valid
        expect(appointment.errors[:payment_method]).to include(
          "country (#{country_vn}) does not match company country (#{country_us})"
        )
      end
    end

    context "when payment_method is nil" do
      it "skips the validation" do
        appointment = CompanyPaymentMethodAppointment.new(company: company, payment_method: nil)
        appointment.valid?
        expect(appointment.errors[:payment_method]).not_to include(/country code/)
      end
    end
  end
end
