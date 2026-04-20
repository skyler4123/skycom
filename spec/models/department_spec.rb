# spec/models/department_spec.rb
require 'rails_helper'

RSpec.describe Department, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:category).optional }
    it { should have_many(:role_appointments).dependent(:destroy) }
    it { should have_many(:roles).through(:role_appointments) }
    it { should have_many(:department_appointments).dependent(:destroy) }
    it { should have_many(:employees).through(:department_appointments) }
  end
end