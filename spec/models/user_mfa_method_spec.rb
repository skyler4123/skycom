# spec/models/user_mfa_method_spec.rb
require "rails_helper"

RSpec.describe UserMfaMethod, type: :model do
  describe "table" do
    it "uses user_mfa_methods" do
      expect(described_class.table_name).to eq("user_mfa_methods")
    end
  end

  describe "associations" do
    it { should belong_to(:user) }
  end

  describe "validations" do
    it { should validate_presence_of(:method) }
  end

  describe "enums" do
    it { should define_enum_for(:method).with_prefix(true).with_values(totp: 0, webauthn: 1, sms: 2, email: 3) }
  end
end
