# spec/models/address_spec.rb
require 'rails_helper'

RSpec.describe Address, type: :model do
  describe "associations" do
    it { should have_many(:address_appointments).dependent(:destroy) }
    it { should have_many(:users).through(:address_appointments) }
    it { should have_many(:companies).through(:address_appointments) }
    it { should have_many(:branches).through(:address_appointments) }
    it { should have_many(:employees).through(:address_appointments) }
    it { should have_many(:employee_groups).through(:address_appointments) }
    it { should have_many(:customers).through(:address_appointments) }
    it { should have_many(:customer_groups).through(:address_appointments) }
    it { should have_many(:departments).through(:address_appointments) }
  end

  describe "validations" do
    it { should validate_presence_of(:line_1) }
    it { should validate_presence_of(:city) }
    it { should validate_presence_of(:country_code) }
  end

  describe "enums" do
    it { should define_enum_for(:country_code) }
  end
end