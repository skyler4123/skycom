# spec/models/address_spec.rb
require 'rails_helper'

RSpec.describe Address, type: :model do
  describe "associations" do
    it { should have_many(:address_branch_appointments).dependent(:destroy) }
    it { should have_many(:branches).through(:address_branch_appointments) }
    it { should have_many(:address_company_appointments).dependent(:destroy) }
    it { should have_many(:companies).through(:address_company_appointments) }
    it { should have_many(:address_customer_appointments).dependent(:destroy) }
    it { should have_many(:customers).through(:address_customer_appointments) }
    it { should have_many(:address_customer_group_appointments).dependent(:destroy) }
    it { should have_many(:customer_groups).through(:address_customer_group_appointments) }
    it { should have_many(:address_department_appointments).dependent(:destroy) }
    it { should have_many(:departments).through(:address_department_appointments) }
    it { should have_many(:address_employee_appointments).dependent(:destroy) }
    it { should have_many(:employees).through(:address_employee_appointments) }
    it { should have_many(:address_employee_group_appointments).dependent(:destroy) }
    it { should have_many(:employee_groups).through(:address_employee_group_appointments) }
    it { should have_many(:address_user_appointments).dependent(:destroy) }
    it { should have_many(:users).through(:address_user_appointments) }
  end

  describe "validations" do
    it { should validate_presence_of(:line_1) }
    it { should validate_presence_of(:city) }
    it { should validate_presence_of(:country) }
  end

  describe "enums" do
    it { should define_enum_for(:country) }
  end
end
