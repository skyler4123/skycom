# spec/models/employee_group_spec.rb
require 'rails_helper'

RSpec.describe EmployeeGroup, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:branch).optional }
    it { should belong_to(:category).optional }
    it { should have_many(:employee_group_appointments).dependent(:destroy) }
    it { should have_many(:employees).through(:employee_group_appointments) }
    it { should have_many(:role_appointments).dependent(:destroy) }
    it { should have_many(:roles).through(:role_appointments) }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name).scoped_to(:company_id) }
    it { should validate_length_of(:name).is_at_most(255) }
  end
end