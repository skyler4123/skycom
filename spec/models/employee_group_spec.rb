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
end
