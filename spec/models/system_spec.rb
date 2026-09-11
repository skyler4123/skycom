# spec/models/system_spec.rb
require 'rails_helper'

RSpec.describe System, type: :model do
  subject { System.new(code: "system_test") }

  describe "validations" do
    it { should validate_presence_of(:code) }
    it { should validate_uniqueness_of(:code) }
  end

  describe "enums" do
    it { should define_enum_for(:country).with_values(System::SYSTEM_COUNTRY_CODES).with_prefix(:country) }
    it { should define_enum_for(:currency).with_values(CURRENCIE_CODES).with_prefix(:currency) }
  end

  describe "geographic records" do
    it "allows multiple System records with distinct codes (global, US, VN)" do
      expect {
        System.create!(code: "system_global", name: "Global System", country: :global, currency: :usd)
        System.create!(code: "system_us", name: "US System", country: :us, currency: :usd)
        System.create!(code: "system_vn", name: "VN System", country: :vn, currency: :vnd)
      }.not_to raise_error
      expect(System.where(code: %w[system_global system_us system_vn]).count).to eq(3)
      expect(System.find_by(code: "system_global")).to be_country_global
    end

    it "rejects duplicate codes" do
      System.create!(code: "system_us", name: "US System", country: :us, currency: :usd)
      duplicate = System.new(code: "system_us", name: "US System Copy")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:code]).to be_present
    end
  end
end
