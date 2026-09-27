# spec/models/branch_payment_method_appointment_spec.rb
require 'rails_helper'

RSpec.describe BranchPaymentMethodAppointment, type: :model do
  describe "associations" do
    it { should belong_to(:payment_method) }
    it { should belong_to(:company) }
    it { should belong_to(:branch) }
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

  describe "company_id derivation" do
    let(:company) { create(:company) }
    let(:payment_method) { create(:payment_method) }

    before { company.update_column(:country, COUNTRY_CODES[:us]) }

    it "derives company_id from the branch" do
      branch = create(:branch, company: company)
      appointment = BranchPaymentMethodAppointment.new(
        branch: branch,
        payment_method: payment_method,
        name: "Cash for #{branch.name}",
        code: "CSH-#{SecureRandom.hex(4).upcase}",
        business_type: :in_store
      )
      appointment.valid?
      expect(appointment.company_id).to eq(company.id)
    end

    it "is invalid when the branch belongs to another company" do
      branch = create(:branch, company: company)
      other_company = create(:company)
      appointment = BranchPaymentMethodAppointment.new(
        company: other_company,
        branch: branch,
        payment_method: payment_method,
        name: "Cash for #{branch.name}",
        code: "CSH-#{SecureRandom.hex(4).upcase}",
        business_type: :in_store
      )
      expect(appointment).not_to be_valid
      expect(appointment.errors[:branch]).to include("does not belong to this company")
    end
  end

  describe "branch-level validation" do
    let(:company) { create(:company) }
    let(:payment_method) { create(:payment_method) }

    before { company.update_column(:country, COUNTRY_CODES[:us]) }

    context "when no active company-level appointment exists for the payment method" do
      it "is invalid for a branch-level appointment" do
        branch = create(:branch, company: company)
        appointment = BranchPaymentMethodAppointment.new(
          company: company,
          branch: branch,
          payment_method: payment_method,
          name: "Cash for #{branch.name}",
          code: "BR-CSH-#{SecureRandom.hex(4).upcase}",
          business_type: :in_store,
          lifecycle_status: :active
        )
        expect(appointment).not_to be_valid
        expect(appointment.errors[:branch]).to include(
          "payment method is not active at the company level"
        )
      end
    end

    context "when an active company-level appointment exists for the payment method" do
      it "is valid for a branch-level appointment" do
        CompanyPaymentMethodAppointment.create!(
          company: company,
          payment_method: payment_method,
          name: "Cash for #{company.name}",
          code: "CSH-#{SecureRandom.hex(4).upcase}",
          business_type: :in_store,
          lifecycle_status: :active
        )
        branch = create(:branch, company: company)
        appointment = BranchPaymentMethodAppointment.new(
          company: company,
          branch: branch,
          payment_method: payment_method,
          name: "Cash for #{branch.name}",
          code: "BR-CSH-#{SecureRandom.hex(4).upcase}",
          business_type: :in_store,
          lifecycle_status: :active
        )
        expect(appointment).to be_valid
      end
    end

    context "when the company-level appointment exists but is not active" do
      it "is invalid for a branch-level appointment" do
        CompanyPaymentMethodAppointment.create!(
          company: company,
          payment_method: payment_method,
          name: "Cash for #{company.name}",
          code: "CSH-#{SecureRandom.hex(4).upcase}",
          business_type: :in_store,
          lifecycle_status: :inactive
        )
        branch = create(:branch, company: company)
        appointment = BranchPaymentMethodAppointment.new(
          company: company,
          branch: branch,
          payment_method: payment_method,
          name: "Cash for #{branch.name}",
          code: "BR-CSH-#{SecureRandom.hex(4).upcase}",
          business_type: :in_store,
          lifecycle_status: :active
        )
        expect(appointment).not_to be_valid
      end
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

      it "is valid (with an active company-level appointment)" do
        CompanyPaymentMethodAppointment.create!(
          company: company,
          payment_method: payment_method,
          name: "Cash for #{company.name}",
          code: "CSH-#{SecureRandom.hex(4).upcase}",
          business_type: :in_store,
          lifecycle_status: :active
        )
        branch = create(:branch, company: company)
        appointment = build(:branch_payment_method_appointment, company: company, branch: branch, payment_method: payment_method)
        expect(appointment).to be_valid
      end
    end

    context "when country codes do not match" do
      before do
        payment_method.update_column(:country, country_vn)
      end

      it "is invalid with a mismatch error" do
        branch = create(:branch, company: company)
        appointment = build(:branch_payment_method_appointment, company: company, branch: branch, payment_method: payment_method)
        expect(appointment).not_to be_valid
        expect(appointment.errors[:payment_method]).to include(
          "country (#{country_vn}) does not match company country (#{country_us})"
        )
      end
    end
  end
end
