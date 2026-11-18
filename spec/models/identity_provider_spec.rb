# spec/models/identity_provider_spec.rb
require "rails_helper"

RSpec.describe IdentityProvider, type: :model do
  describe "table" do
    it "uses identity_providers" do
      expect(described_class.table_name).to eq("identity_providers")
    end
  end

  describe "associations" do
    it { should belong_to(:company).optional }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_most(255) }
  end

  describe "enums" do
    it { should define_enum_for(:provider_type).with_prefix(true).with_values(saml: 0, oidc: 1) }
  end
end
