# spec/models/payment_method_appointment_spec.rb
require 'rails_helper'

RSpec.describe PaymentMethodAppointment, type: :model do
  describe "associations" do
    it { should belong_to(:payment_method) }
    it { should belong_to(:company) }
    it { should belong_to(:appoint_to) }
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

  describe "default appoint_to" do
    let(:company) { create(:company) }
    let(:payment_method) { create(:payment_method) }

    before { company.update_column(:country, COUNTRY_CODES[:us]) }

    it "defaults appoint_to to the company when only a company is provided" do
      appointment = PaymentMethodAppointment.new(
        company: company,
        payment_method: payment_method,
        name: "Cash for #{company.name}",
        code: "CSH-#{SecureRandom.hex(4).upcase}",
        business_type: :in_store
      )
      appointment.valid?
      expect(appointment.appoint_to).to eq(company)
    end
  end

  describe "company_id derivation" do
    let(:company) { create(:company) }
    let(:payment_method) { create(:payment_method) }

    before { company.update_column(:country, COUNTRY_CODES[:us]) }

    context "when appoint_to is a Branch" do
      it "derives company_id from the branch" do
        branch = create(:branch, company: company)
        appointment = PaymentMethodAppointment.new(
          appoint_to: branch,
          payment_method: payment_method,
          name: "Cash for #{branch.name}",
          code: "CSH-#{SecureRandom.hex(4).upcase}",
          business_type: :in_store
        )
        appointment.valid?
        expect(appointment.company_id).to eq(company.id)
      end
    end

    context "when appoint_to is a Company" do
      it "derives company_id from the company" do
        appointment = PaymentMethodAppointment.new(
          appoint_to: company,
          payment_method: payment_method,
          name: "Cash for #{company.name}",
          code: "CSH-#{SecureRandom.hex(4).upcase}",
          business_type: :in_store
        )
        appointment.valid?
        expect(appointment.company_id).to eq(company.id)
      end
    end
  end

  describe "scopes" do
    let(:company) { create(:company) }
    let(:payment_method) { create(:payment_method) }

    before { company.update_column(:country, COUNTRY_CODES[:us]) }

    it "company_level returns only appointments whose appoint_to is a Company" do
      branch = create(:branch, company: company)
      company_appointment = PaymentMethodAppointment.create!(
        appoint_to: company,
        payment_method: payment_method,
        name: "Cash for #{company.name}",
        code: "CSH-#{SecureRandom.hex(4).upcase}",
        business_type: :in_store,
        lifecycle_status: :active
      )
      branch_appointment = PaymentMethodAppointment.create!(
        appoint_to: branch,
        payment_method: payment_method,
        name: "Cash for #{branch.name}",
        code: "BR-CSH-#{SecureRandom.hex(4).upcase}",
        business_type: :in_store,
        lifecycle_status: :active
      )

      expect(PaymentMethodAppointment.company_level).to include(company_appointment)
      expect(PaymentMethodAppointment.company_level).not_to include(branch_appointment)
    end

    it "branch_level returns only appointments whose appoint_to is a Branch" do
      branch = create(:branch, company: company)
      company_appointment = PaymentMethodAppointment.create!(
        appoint_to: company,
        payment_method: payment_method,
        name: "Cash for #{company.name}",
        code: "CSH-#{SecureRandom.hex(4).upcase}",
        business_type: :in_store,
        lifecycle_status: :active
      )
      branch_appointment = PaymentMethodAppointment.create!(
        appoint_to: branch,
        payment_method: payment_method,
        name: "Cash for #{branch.name}",
        code: "BR-CSH-#{SecureRandom.hex(4).upcase}",
        business_type: :in_store,
        lifecycle_status: :active
      )

      expect(PaymentMethodAppointment.branch_level).to include(branch_appointment)
      expect(PaymentMethodAppointment.branch_level).not_to include(company_appointment)
    end
  end

  describe "branch-level validation" do
    let(:company) { create(:company) }
    let(:payment_method) { create(:payment_method) }

    before { company.update_column(:country, COUNTRY_CODES[:us]) }

    context "when no active company-level appointment exists for the payment method" do
      it "is invalid for a branch-level appointment" do
        branch = create(:branch, company: company)
        appointment = PaymentMethodAppointment.new(
          appoint_to: branch,
          payment_method: payment_method,
          name: "Cash for #{branch.name}",
          code: "BR-CSH-#{SecureRandom.hex(4).upcase}",
          business_type: :in_store,
          lifecycle_status: :active
        )
        expect(appointment).not_to be_valid
        expect(appointment.errors[:appoint_to]).to include(
          "payment method is not active at the company level"
        )
      end
    end

    context "when an active company-level appointment exists for the payment method" do
      it "is valid for a branch-level appointment" do
        PaymentMethodAppointment.create!(
          appoint_to: company,
          payment_method: payment_method,
          name: "Cash for #{company.name}",
          code: "CSH-#{SecureRandom.hex(4).upcase}",
          business_type: :in_store,
          lifecycle_status: :active
        )
        branch = create(:branch, company: company)
        appointment = PaymentMethodAppointment.new(
          appoint_to: branch,
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
        PaymentMethodAppointment.create!(
          appoint_to: company,
          payment_method: payment_method,
          name: "Cash for #{company.name}",
          code: "CSH-#{SecureRandom.hex(4).upcase}",
          business_type: :in_store,
          lifecycle_status: :inactive
        )
        branch = create(:branch, company: company)
        appointment = PaymentMethodAppointment.new(
          appoint_to: branch,
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

  describe "lifecycle cascade" do
    let(:company) { create(:company) }
    let(:payment_method) { create(:payment_method) }
    let(:branch) { create(:branch, company: company) }

    before { company.update_column(:country, COUNTRY_CODES[:us]) }

    it "mirrors lifecycle_status changes from the company-level appointment to branch-level appointments" do
      company_appointment = PaymentMethodAppointment.create!(
        appoint_to: company,
        payment_method: payment_method,
        name: "Cash for #{company.name}",
        code: "CSH-#{SecureRandom.hex(4).upcase}",
        business_type: :in_store,
        lifecycle_status: :active
      )
      branch_appointment = PaymentMethodAppointment.create!(
        appoint_to: branch,
        payment_method: payment_method,
        name: "Cash for #{branch.name}",
        code: "BR-CSH-#{SecureRandom.hex(4).upcase}",
        business_type: :in_store,
        lifecycle_status: :active
      )

      company_appointment.update!(lifecycle_status: :inactive)

      expect(branch_appointment.reload.lifecycle_status).to eq("inactive")
    end

    it "does not cascade when the change is on a branch-level appointment" do
      company_appointment = PaymentMethodAppointment.create!(
        appoint_to: company,
        payment_method: payment_method,
        name: "Cash for #{company.name}",
        code: "CSH-#{SecureRandom.hex(4).upcase}",
        business_type: :in_store,
        lifecycle_status: :active
      )
      branch_appointment = PaymentMethodAppointment.create!(
        appoint_to: branch,
        payment_method: payment_method,
        name: "Cash for #{branch.name}",
        code: "BR-CSH-#{SecureRandom.hex(4).upcase}",
        business_type: :in_store,
        lifecycle_status: :active
      )

      branch_appointment.update!(lifecycle_status: :inactive)

      expect(company_appointment.reload.lifecycle_status).to eq("active")
    end

    it "does not cascade to branch appointments of other payment methods" do
      other_payment_method = create(:payment_method)
      company_appointment = PaymentMethodAppointment.create!(
        appoint_to: company,
        payment_method: payment_method,
        name: "Cash for #{company.name}",
        code: "CSH-#{SecureRandom.hex(4).upcase}",
        business_type: :in_store,
        lifecycle_status: :active
      )
      PaymentMethodAppointment.create!(
        appoint_to: company,
        payment_method: other_payment_method,
        name: "Other for #{company.name}",
        code: "OTH-#{SecureRandom.hex(4).upcase}",
        business_type: :in_store,
        lifecycle_status: :active
      )
      company_appointment.update!(lifecycle_status: :inactive)

      other_branch_appointment = PaymentMethodAppointment.create!(
        appoint_to: branch,
        payment_method: other_payment_method,
        name: "Other for #{branch.name}",
        code: "OTH-BR-#{SecureRandom.hex(4).upcase}",
        business_type: :in_store,
        lifecycle_status: :active
      )

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
        appointment = build(:payment_method_appointment, company: company, payment_method: payment_method)
        expect(appointment).to be_valid
      end
    end

    context "when country codes do not match" do
      before do
        payment_method.update_column(:country, country_vn)
      end

      it "is invalid with a mismatch error" do
        appointment = build(:payment_method_appointment, company: company, payment_method: payment_method)
        expect(appointment).not_to be_valid
        expect(appointment.errors[:payment_method]).to include(
          "country (#{country_vn}) does not match company country (#{country_us})"
        )
      end
    end

    context "when payment_method is nil" do
      it "skips the validation" do
        appointment = PaymentMethodAppointment.new(company: company, payment_method: nil)
        appointment.valid?
        expect(appointment.errors[:payment_method]).not_to include(/country code/)
      end
    end
  end
end
