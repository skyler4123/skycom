# spec/models/role_spec.rb
require 'rails_helper'

RSpec.describe Role, type: :model do
  describe "associations" do
    it { should belong_to(:company).touch(true) }
    it { should belong_to(:branch).optional }
    it { should have_many(:policy_role_appointments).dependent(:destroy) }
    it { should have_many(:policies).through(:policy_role_appointments) }
    it { should have_many(:role_tag_appointments).dependent(:destroy) }
    it { should have_many(:tags).through(:role_tag_appointments) }
    it { should have_many(:employee_role_appointments).dependent(:destroy) }
    it { should have_many(:employees).through(:employee_role_appointments) }
    it { should have_many(:customer_role_appointments).dependent(:destroy) }
    it { should have_many(:customers).through(:customer_role_appointments) }
    it { should have_many(:customer_group_role_appointments).dependent(:destroy) }
    it { should have_many(:customer_groups).through(:customer_group_role_appointments) }
    it { should have_many(:department_role_appointments).dependent(:destroy) }
    it { should have_many(:departments).through(:department_role_appointments) }
    it { should have_many(:employee_group_role_appointments).dependent(:destroy) }
    it { should have_many(:employee_groups).through(:employee_group_role_appointments) }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:business_type) }
    it { should validate_length_of(:name).is_at_most(100) }
  end

  describe "enums" do
    it { should define_enum_for(:lifecycle_status) }
    it { should define_enum_for(:workflow_status) }
    it { should define_enum_for(:business_type).with_values(owner: 0, administrative: 1, management: 2, technical: 3, support: 4) }
    it { should define_enum_for(:model_type) }
  end
end
