# spec/models/payment_method_appointment_spec.rb
require 'rails_helper'

RSpec.describe PaymentMethodAppointment, type: :model do
  describe "associations" do
    it { should belong_to(:payment_method) }
    it { should belong_to(:company) }
    it { should belong_to(:branch).optional }
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
