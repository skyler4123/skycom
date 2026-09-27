# spec/models/department_spec.rb
require 'rails_helper'

RSpec.describe Department, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:category) }
    it { should have_many(:department_role_appointments).dependent(:destroy) }
    it { should have_many(:roles).through(:department_role_appointments) }
    it { should have_many(:department_employee_appointments).dependent(:destroy) }
    it { should have_many(:employees).through(:department_employee_appointments) }
  end
  it_behaves_like "property_mapping concern", Department
end
