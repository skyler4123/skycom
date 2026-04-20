# spec/models/tag_spec.rb
require 'rails_helper'

RSpec.describe Tag, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should have_many(:tag_appointments).dependent(:destroy) }
    it { should have_many(:companies).through(:tag_appointments) }
    it { should have_many(:branches).through(:tag_appointments) }
    it { should have_many(:employees).through(:tag_appointments) }
    it { should have_many(:employee_groups).through(:tag_appointments) }
    it { should have_many(:customers).through(:tag_appointments) }
    it { should have_many(:customer_groups).through(:tag_appointments) }
    it { should have_many(:services).through(:tag_appointments) }
    it { should have_many(:service_groups).through(:tag_appointments) }
    it { should have_many(:facilities).through(:tag_appointments) }
    it { should have_many(:facility_groups).through(:tag_appointments) }
    it { should have_many(:products).through(:tag_appointments) }
    it { should have_many(:product_groups).through(:tag_appointments) }
  end

  describe "validations" do
    it { should validate_presence_of(:key) }
  end
end