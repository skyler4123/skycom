# spec/models/customer_user_appointment_spec.rb
require "rails_helper"

RSpec.describe CustomerUserAppointment, type: :model do
  describe "table" do
    it "uses customer_user_appointments" do
      expect(described_class.table_name).to eq("customer_user_appointments")
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:customer) }
    it { should belong_to(:user) }
  end

  describe "validations" do
    it "declares user_id uniqueness scoped to customer_id" do
      validator = described_class.validators_on(:user_id).detect { |v| v.is_a?(ActiveRecord::Validations::UniquenessValidator) }
      expect(validator).to be_present
      expect(Array(validator.options[:scope]).map(&:to_s)).to eq(%w[customer_id])
    end
  end

  describe "enums" do
    it { should define_enum_for(:role).with_prefix(true).with_values(viewer: 0, buyer: 1, approver: 2, admin: 3) }
  end
end
